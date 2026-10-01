import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { authorization_code } = await req.json()
    if (!authorization_code) {
      throw new Error('authorization_code is required')
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('No authorization header')

    // 1. Supabase User Client 생성 (유저의 권한으로 RPC를 실행하기 위함)
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: {
            Authorization: authHeader
          }
        }
      }
    )

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await userClient.auth.getUser(token)
    if (userError || !user) throw new Error('Unauthorized user')

    // 3. Apple 설정 정보 로드
    const teamId = Deno.env.get('APPLE_TEAM_ID')
    const clientId = Deno.env.get('APPLE_CLIENT_ID') // ex: com.mettie.app
    const keyId = Deno.env.get('APPLE_KEY_ID')
    const privateKeyStr = Deno.env.get('APPLE_PRIVATE_KEY')

    if (!teamId || !clientId || !keyId || !privateKeyStr) {
      throw new Error('Apple environment variables are not configured properly')
    }

    // 4. .p8 포맷 파싱 및 Apple JWT (client_secret) 생성
    // 줄바꿈이 올바르게 들어가도록 치환
    const formattedKey = privateKeyStr.replace(/\\n/g, '\n')
    const privateKey = await jose.importPKCS8(formattedKey, 'ES256')

    const clientSecret = await new jose.SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: keyId })
      .setIssuer(teamId)
      .setIssuedAt()
      .setExpirationTime('10m')
      .setAudience('https://appleid.apple.com')
      .setSubject(clientId)
      .sign(privateKey)

    // 5. Authorization Code를 Apple에 보내서 Refresh Token 교환
    const tokenResponse = await fetch('https://appleid.apple.com/auth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        code: authorization_code,
        grant_type: 'authorization_code'
      })
    })

    const tokenData = await tokenResponse.json()
    if (!tokenData.refresh_token) {
      console.error('Failed to get refresh token:', tokenData)
      throw new Error('Failed to get refresh token from Apple')
    }

    // 6. Refresh Token을 이용해 최종적으로 Apple Token Revoke
    const revokeResponse = await fetch('https://appleid.apple.com/auth/revoke', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: tokenData.refresh_token,
        token_type_hint: 'refresh_token'
      })
    })

    if (!revokeResponse.ok) {
      throw new Error('Failed to revoke Apple token')
    }

    // 7. Revoke 성공 시, Supabase DB에서 해당 유저 완전히 삭제 (RPC 호출)
    const { error: deleteError } = await userClient.rpc('delete_user')
    if (deleteError) {
      throw deleteError
    }

    return new Response(
      JSON.stringify({ message: 'User deleted and Apple token revoked successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    console.error('Edge Function Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
