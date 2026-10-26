#!/bin/zsh
# 로컬 dev DB 데모 데이터 (운영 DB에는 절대 쓰지 않는다)
# - 계정: test@test.test(나, owner) / mom@test.test(엄마, partner), 비밀번호 testtest
# - 펫: 당뇨 고양이 Coco(란투스 2 IU, 07:00/19:00), 당뇨가 아닌 강아지 Bori
# - 기록: 오늘 기준 지난 14일. 혼합 급여, 9일 전 저녁 생략, 4일 전 nadir 저혈당 72
# 사용: supabase db reset 후 ./supabase/dev/seed_demo.sh
set -euo pipefail
API=http://127.0.0.1:54321
DB=supabase_db_$(basename "$(git rev-parse --show-toplevel)")
SK=$(supabase status -o json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['SERVICE_ROLE_KEY'])")

mk() {
  curl -s -X POST "$API/auth/v1/admin/users" -H "apikey: $SK" -H "Authorization: Bearer $SK" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"testtest\",\"email_confirm\":true,\"user_metadata\":{\"full_name\":\"$2\"}}" |
    python3 -c "import sys,json; print(json.load(sys.stdin)['id'])"
}
ME=$(mk test@test.test 나)
MOM=$(mk mom@test.test 엄마)

python3 - "$ME" "$MOM" <<'EOF' | docker exec -i "$DB" psql -U postgres -v ON_ERROR_STOP=1 -q
import random, datetime as dt, sys
random.seed(7)
ME, MOM = sys.argv[1], sys.argv[2]
F = 'f1000000-0000-0000-0000-000000000001'
P = 'e1000000-0000-0000-0000-000000000001'
P2 = 'e1000000-0000-0000-0000-000000000002'
now = dt.datetime.now().replace(second=0, microsecond=0)
print(f"insert into public.families(id,created_by) values ('{F}','{ME}');")
print(f"insert into public.user_families(user_id,family_id,role) values ('{ME}','{F}','owner'),('{MOM}','{F}','partner');")
diag = (now - dt.timedelta(days=42)).date()
print(f"""insert into public.pets(id,family_id,name,species,breed,sex,is_neutered,date_of_birth,diagnosis,diagnosed_at,insulin_type,insulin_unit_iu,
 target_glucose_min,target_glucose_max,weight_kg,body_condition_score,vet_clinic,conditions,dosing_times,insulin_concentration,syringe_type,
 glucose_meter,default_food_wet,default_food_dry) values
 ('{P}','{F}','Coco','cat','코리안 숏헤어','male',true,'2014-04-10','당뇨','{diag}','란투스(Lantus)',2,100,300,4.8,6,'24시 하늘동물병원',
  '{{diabetes}}','{{07:00,19:00}}','U-100','U-100','알파트랙 3','로얄캐닌 다이아베틱','힐스 m/d'),
 ('{P2}','{F}','Bori','dog','말티즈','female',true,'2019-06-01',null,null,null,null,null,null,3.4,5,'24시 하늘동물병원',
  '{{}}','{{}}',null,null,null,null,null);""")
rows = []
def rec(pet, t, w, **k):
    if t <= now: rows.append((pet, t, w, k))
for d in range(14, -1, -1):
    day = (now - dt.timedelta(days=d)).replace(hour=0, minute=0)
    trend = d / 14
    for inj_h in (7, 19):
        t = day + dt.timedelta(hours=inj_h, minutes=random.randint(-10, 10))
        w = MOM if (inj_h == 7 and d % 3 != 1) else ME
        pre = int(220 + 130 * trend + random.randint(-30, 30))
        skipped = (d == 9 and inj_h == 19)
        rec(P, t - dt.timedelta(minutes=15), w, glucose_value=pre, glucose_type='pre_meal')
        rec(P, t - dt.timedelta(minutes=5), w, food_brand='로얄캐닌 다이아베틱', food_type='wet',
            food_amount_g=15 if skipped else random.choice([40, 45]), appetite='partial' if skipped else 'good')
        if not skipped:
            rec(P, t - dt.timedelta(minutes=5), w, food_brand='힐스 m/d', food_type='dry', food_amount_g=random.choice([10, 15]))
        rec(P, t, w, insulin_dose=0 if skipped else (2.5 if d > 8 else 2), insulin_type='란투스(Lantus)',
            injection_status='skipped' if skipped else 'given', notes='밥을 거의 안 먹어서 인슐린 생략' if skipped else None)
        if inj_h == 7 and d % 2 == 0:
            nad = 72 if d == 4 else int(120 + 80 * trend + random.randint(-25, 25))
            rec(P, t + dt.timedelta(hours=6), MOM, glucose_value=nad, glucose_type='nadir',
                symptom_tags='{lethargy}' if d == 4 else None)
    if d % 7 == 0:
        rec(P, day + dt.timedelta(hours=8), ME, weight_kg=round(4.8 - 0.05 * (14 - d) / 7, 2),
            water_intake='increased' if d > 7 else 'normal', urination='polyuria' if d > 7 else 'normal')
        rec(P2, day + dt.timedelta(hours=8, minutes=10), ME, weight_kg=round(3.4 + 0.02 * (14 - d) / 7, 2))
cols = ['pet_id','writer_id','recorded_at','glucose_value','glucose_type','insulin_dose','insulin_type','injection_status',
        'food_brand','food_type','food_amount_g','appetite','weight_kg','water_intake','urination','notes','symptom_tags']
lit = lambda v: 'null' if v is None else (str(v) if isinstance(v, (int, float)) else "'" + str(v).replace("'", "''") + "'")
vals = []
for pet, t, w, k in rows:
    k = dict(k); k.update(pet_id=pet, writer_id=w, recorded_at=t.strftime('%Y-%m-%d %H:%M:00') + dt.datetime.now().astimezone().strftime('%z'))
    vals.append('(' + ','.join(lit(k.get(c)) for c in cols) + ')')
print('insert into public.records(%s) values\n%s;' % (','.join(cols), ',\n'.join(vals)))
EOF
docker exec "$DB" psql -U postgres -tAc "select p.name || ': ' || count(r.*) from pets p left join records r on r.pet_id=p.id group by p.name"
