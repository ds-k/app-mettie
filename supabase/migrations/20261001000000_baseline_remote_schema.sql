


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."delete_user"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  -- 현재 요청한 유저(auth.uid)와 일치하는 계정을 auth.users에서 삭제
  DELETE FROM auth.users WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."delete_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url)
  VALUES (
    new.id,
    new.email,
    COALESCE(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      ''
    ),
    COALESCE(
      new.raw_user_meta_data->>'avatar_url',
      new.raw_user_meta_data->>'picture',
      ''
    )
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_update_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- 메타데이터가 실제로 변경되었을 때만 업데이트 수행
  IF new.raw_user_meta_data IS DISTINCT FROM old.raw_user_meta_data THEN
    UPDATE public.users
    SET 
      full_name = COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', public.users.full_name),
      avatar_url = COALESCE(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', public.users.avatar_url)
    WHERE id = new.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_update_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_user_family_deletion"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- 삭제되는 멤버의 권한이 'owner'라면, 해당 가족방(family_id)을 폭파시킵니다.
  -- 가족방(families)이 폭파되면 FK CASCADE 옵션에 의해 남은 파트너의 user_families, pets, records 모두 자동 삭제됩니다.
  IF OLD.role = 'owner' THEN
    DELETE FROM families WHERE id = OLD.family_id;
  END IF;
  RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."handle_user_family_deletion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."join_family_with_code"("invite_code" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  target_family_id uuid;
  exp_date timestamptz;
BEGIN
  SELECT family_id, expires_at INTO target_family_id, exp_date
  FROM invitations WHERE code = invite_code;

  IF target_family_id IS NULL THEN RAISE EXCEPTION '유효하지 않은 초대 코드입니다.'; END IF;
  IF exp_date < now() THEN RAISE EXCEPTION '만료된 초대 코드입니다.'; END IF;
  IF EXISTS (SELECT 1 FROM user_families WHERE user_id = auth.uid() AND family_id = target_family_id) THEN
    RAISE EXCEPTION '이미 연결된 가족입니다.';
  END IF;

  INSERT INTO user_families (user_id, family_id, role)
  VALUES (auth.uid(), target_family_id, 'partner');
END;
$$;


ALTER FUNCTION "public"."join_family_with_code"("invite_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."families" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" DEFAULT "auth"."uid"()
);


ALTER TABLE "public"."families" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invitations" (
    "code" character varying(6) NOT NULL,
    "family_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."invitations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "family_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "species" "text" NOT NULL,
    "breed" "text",
    "sex" "text",
    "is_neutered" boolean DEFAULT false,
    "date_of_birth" "date",
    "diagnosis" "text",
    "diagnosed_at" "date",
    "insulin_type" "text",
    "insulin_unit_iu" numeric,
    "target_glucose_min" integer DEFAULT 100,
    "target_glucose_max" integer,
    "weight_kg" numeric,
    "body_condition_score" integer,
    "vet_clinic" "text",
    "vet_memo" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."pets" REPLICA IDENTITY FULL;


ALTER TABLE "public"."pets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pet_id" "uuid" NOT NULL,
    "writer_id" "uuid" NOT NULL,
    "recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "glucose_value" integer,
    "glucose_type" "text",
    "measurement_device" "text",
    "is_stress_flag" boolean DEFAULT false,
    "insulin_dose" numeric,
    "insulin_type" "text",
    "injection_status" "text",
    "food_brand" "text",
    "food_type" "text",
    "food_amount_g" numeric,
    "treat_memo" "text",
    "weight_kg" numeric,
    "body_condition_score" integer,
    "water_intake" "text",
    "urination" "text",
    "appetite" "text",
    "activity_level" integer,
    "vomit_count" integer DEFAULT 0,
    "stool_status" "text",
    "symptom_tags" "text"[],
    "notes" "text",
    "attachments" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."records" REPLICA IDENTITY FULL;


ALTER TABLE "public"."records" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_families" (
    "user_id" "uuid" NOT NULL,
    "family_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'owner'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_families" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."families"
    ADD CONSTRAINT "families_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_pkey" PRIMARY KEY ("code");



ALTER TABLE ONLY "public"."pets"
    ADD CONSTRAINT "pets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_families"
    ADD CONSTRAINT "user_families_pkey" PRIMARY KEY ("user_id", "family_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "trigger_user_family_deletion" AFTER DELETE ON "public"."user_families" FOR EACH ROW EXECUTE FUNCTION "public"."handle_user_family_deletion"();



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_family_id_fkey" FOREIGN KEY ("family_id") REFERENCES "public"."families"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pets"
    ADD CONSTRAINT "pets_family_id_fkey" FOREIGN KEY ("family_id") REFERENCES "public"."families"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_pet_id_fkey" FOREIGN KEY ("pet_id") REFERENCES "public"."pets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_writer_id_fkey" FOREIGN KEY ("writer_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_families"
    ADD CONSTRAINT "user_families_family_id_fkey" FOREIGN KEY ("family_id") REFERENCES "public"."families"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_families"
    ADD CONSTRAINT "user_families_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Anyone can read valid invitations" ON "public"."invitations" FOR SELECT TO "authenticated" USING (("expires_at" > "now"()));



CREATE POLICY "Enable delete for users in family" ON "public"."user_families" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Enable insert for authenticated users" ON "public"."user_families" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Enable insert for authenticated users only" ON "public"."families" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable select for authenticated users" ON "public"."invitations" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for family members or creator" ON "public"."families" FOR SELECT TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR ("id" IN ( SELECT "user_families"."family_id"
   FROM "public"."user_families"
  WHERE ("user_families"."user_id" = "auth"."uid"())))));



CREATE POLICY "Enable select for users in family" ON "public"."user_families" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Enable update for users based on id" ON "public"."users" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "Enable update for users in family" ON "public"."user_families" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Manage pets within family" ON "public"."pets" USING (("family_id" IN ( SELECT "user_families"."family_id"
   FROM "public"."user_families"
  WHERE ("user_families"."user_id" = "auth"."uid"())))) WITH CHECK (("family_id" IN ( SELECT "user_families"."family_id"
   FROM "public"."user_families"
  WHERE ("user_families"."user_id" = "auth"."uid"()))));



CREATE POLICY "Manage records within family" ON "public"."records" USING (("pet_id" IN ( SELECT "pets"."id"
   FROM "public"."pets"
  WHERE ("pets"."family_id" IN ( SELECT "user_families"."family_id"
           FROM "public"."user_families"
          WHERE ("user_families"."user_id" = "auth"."uid"())))))) WITH CHECK (("pet_id" IN ( SELECT "pets"."id"
   FROM "public"."pets"
  WHERE ("pets"."family_id" IN ( SELECT "user_families"."family_id"
           FROM "public"."user_families"
          WHERE ("user_families"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Users can create invitations for their family" ON "public"."invitations" FOR INSERT TO "authenticated" WITH CHECK (("family_id" IN ( SELECT "user_families"."family_id"
   FROM "public"."user_families"
  WHERE ("user_families"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete their own user_families" ON "public"."user_families" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own profile" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view their own profile" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "View pets within family" ON "public"."pets" FOR SELECT USING (("family_id" IN ( SELECT "user_families"."family_id"
   FROM "public"."user_families"
  WHERE ("user_families"."user_id" = "auth"."uid"()))));



CREATE POLICY "View records within family" ON "public"."records" FOR SELECT USING (("pet_id" IN ( SELECT "pets"."id"
   FROM "public"."pets"
  WHERE ("pets"."family_id" IN ( SELECT "user_families"."family_id"
           FROM "public"."user_families"
          WHERE ("user_families"."user_id" = "auth"."uid"()))))));



ALTER TABLE "public"."families" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invitations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."records" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_families" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."pets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."records";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";





































































































































































GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."families" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."families" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."families" TO "service_role";



GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."invitations" TO "anon";
GRANT ALL ON TABLE "public"."invitations" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."invitations" TO "service_role";



GRANT ALL ON TABLE "public"."pets" TO "anon";
GRANT ALL ON TABLE "public"."pets" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."pets" TO "service_role";



GRANT ALL ON TABLE "public"."records" TO "anon";
GRANT ALL ON TABLE "public"."records" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."records" TO "service_role";



GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."user_families" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."user_families" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."user_families" TO "service_role";



GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."users" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."users" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."users" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "service_role";




































-- public 스키마 덤프에 포함되지 않는 운영 DB 객체 (2026-10-01 운영 DB에서 조회해 수동 추가)
CREATE OR REPLACE TRIGGER "on_auth_user_created" AFTER INSERT ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_user"();
CREATE OR REPLACE TRIGGER "on_auth_user_updated" AFTER UPDATE ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_update_user"();

DROP EVENT TRIGGER IF EXISTS "ensure_rls";
CREATE EVENT TRIGGER "ensure_rls" ON ddl_command_end EXECUTE FUNCTION "public"."rls_auto_enable"();
