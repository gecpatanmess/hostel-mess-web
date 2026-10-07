import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Find the start and end of defaultWeeklyMenu
start_str = "const Map<int, Map<String, String>> defaultWeeklyMenu = {"
idx_start = code.find(start_str)

# Find the end of it, which is before `class RegisteredStudent` or the next major block
idx_end = code.find("};", idx_start) + 2

new_menu = """const Map<int, Map<String, String>> defaultWeeklyMenu = {
  DateTime.monday: {
    'breakfast': 'ચા, કોફી અને પૌંઆ',
    'lunch': 'ભીંડી મસાલા, ચણા, દાલ (મીઠી/તીખી), ચાવલ, રોટી, સલાડ',
    'dinner': 'દમ આલુ, વેજ બિરયાની, રોટી, સલાડ',
  },
  DateTime.tuesday: {
    'breakfast': 'ચા, કોફી, મસાલા પુરી/ મેંદુ વડા',
    'lunch': 'કેબીજ મટર, મુંગ, દહીં/છાશ, દાલ (મીઠી/તીખી), ચાવલ, રોટી, સલાડ, છાશ, ગોળ',
    'dinner': 'મિક્સ વેજ, દાલ ફ્રાય, જીરા રાઇસ, રોટી, સલાડ',
  },
  DateTime.wednesday: {
    'breakfast': 'ચા, કોફી, થેપલા/ચિલા',
    'lunch': 'આલુ ગોબી (ફુલાવર), ચણા મસાલા, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ',
    'dinner': 'દાલ બાટી, લસુન ચટણી, પાપડ, લીંબુ',
  },
  DateTime.thursday: {
    'breakfast': 'ચા, કોફી, ઉપમા',
    'lunch': 'ચણા દાલ, બેગન મસાલા/સોયાબીન, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ, ગોળ',
    'dinner': 'પનીર મસાલા, ફ્રાય રાઇસ, રોટી, સલાડ',
  },
  DateTime.friday: {
    'breakfast': 'ચા, કોફી, આલુ પરાઠા/સેન્ડવીચ ઢોકળા',
    'lunch': 'મિક્સ વેજ (ઊંધિયું), તુવેર, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ/દહીં, સલાડ',
    'dinner': 'ભાજી, પરોઠા, પુલાવ સલાડ',
  },
  DateTime.saturday: {
    'breakfast': 'ચા, કોફી, સમોસા/સેવ ખમણી',
    'lunch': 'આલુ પ્યાસ, ચણા/ ચોલી, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ/દહીં, સલાડ, ગોળ',
    'dinner': 'છોલે ભટુરે, પુરી, મીઠી ખીર',
  },
  DateTime.sunday: {
    'breakfast': 'ચા, કોફી, પાપડી/ગાંઠીયા',
    'lunch': 'આલુ ગોબી, કેબીજ મટર, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ',
    'dinner': 'ઇડલી સંભાર, નારિયેળ ચટણી',
  },
};"""

code = code[:idx_start] + new_menu + code[idx_end:]

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Default Weekly Menu updated!")
