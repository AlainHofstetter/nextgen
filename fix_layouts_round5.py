import os, re

LAYOUTS_DIR = os.path.join('force-app', 'main', 'default', 'layouts')

MISSING_FIELDS = [
    'ValCountHasILVDraft__c',
    'ServicesTotalSupplierCosts__c',
    'ServicesTotalTime__c',
    'BudgetOpenForecast__c',
]

for fieldname in MISSING_FIELDS:
    pattern = re.compile(
        rf'\s*<layoutItems>\s*(?:<behavior>[^<]+</behavior>\s*)?<field>{re.escape(fieldname)}</field>\s*</layoutItems>',
        re.MULTILINE
    )
    for filename in os.listdir(LAYOUTS_DIR):
        if not filename.endswith('.layout-meta.xml'):
            continue
        filepath = os.path.join(LAYOUTS_DIR, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = pattern.sub('', content)
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Removed [{fieldname}] from: {filename}')

# AccountBrand — make sure it's in .forceignore
entry = 'force-app/main/default/layouts/AccountBrand-Account Brand Layout.layout-meta.xml'
with open('.forceignore', 'r', encoding='utf-8') as f:
    fi = f.read()
if entry not in fi:
    with open('.forceignore', 'a', encoding='utf-8') as f:
        f.write(f'\n{entry}\n')
    print('Added AccountBrand to .forceignore')
else:
    print('AccountBrand already in .forceignore — check why it still deploys')

print('\nDone!')
