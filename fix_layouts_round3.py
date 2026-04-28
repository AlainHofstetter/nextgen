import os, re

LAYOUTS_DIR = os.path.join('force-app', 'main', 'default', 'layouts')

# --- Fix 1: Remove missing QuickActions ---
MISSING_ACTIONS = [
    'Case.CloseCase',
    'NewPurchase',
    'Quote.Sync',
]

for action in MISSING_ACTIONS:
    escaped = re.escape(action)
    pattern_quick = re.compile(
        rf'\s*<quickActionListItems>\s*<quickActionName>{escaped}</quickActionName>\s*</quickActionListItems>',
        re.MULTILINE
    )
    pattern_platform = re.compile(
        rf'\s*<platformActionListItems>\s*<actionName>{escaped}</actionName>\s*<actionType>QuickAction</actionType>\s*<sortOrder>\d+</sortOrder>\s*</platformActionListItems>',
        re.MULTILINE
    )
    for filename in os.listdir(LAYOUTS_DIR):
        if not filename.endswith('.layout-meta.xml'):
            continue
        filepath = os.path.join(LAYOUTS_DIR, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = pattern_quick.sub('', content)
        new_content = pattern_platform.sub('', new_content)
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Removed [{action}] from: {filename}')

# --- Fix 2: Remove missing custom fields from layouts ---
MISSING_FIELDS = [
    'VisitorAddressId',
    'ValPackageLockedInvoiceDraft__c',
    'ValCountHasInvoiceDraft__c',
    'BudgetOpenTotalSupplierCosts__c',
    'BudgetOpenTotalTime__c',
    'BudgetOpenForecastAmount__c',
]

for fieldname in MISSING_FIELDS:
    pattern = re.compile(
        rf'\s*<layoutItem>\s*<field>{re.escape(fieldname)}</field>\s*</layoutItem>',
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
            print(f'Removed field [{fieldname}] from: {filename}')

# --- Fix 3: Contract layout — fix the bad XML we introduced ---
# Our previous fix inserted <layoutItem> in the wrong place (inside <layoutItems> closing tag)
# Let's revert that bad insertion and do it correctly
contract_path = os.path.join(LAYOUTS_DIR, 'Contract-Contract Layout.layout-meta.xml')
with open(contract_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the badly placed layoutItem we added before
bad_fix = re.compile(
    r'</layoutItems>\s*<layoutItem>\s*<field>Pricebook2Id</field>\s*</layoutItem>',
    re.MULTILINE
)
content = bad_fix.sub('</layoutItems>', content)

# Now add Pricebook2Id correctly inside the first <layoutItems> block
if 'Pricebook2Id' not in content:
    content = content.replace(
        '<layoutItems>',
        '<layoutItems>\n            <layoutItem>\n                <field>Pricebook2Id</field>\n            </layoutItem>',
        1  # only first occurrence
    )
    print('Fixed: Contract layout — added Pricebook2Id correctly')
else:
    print('Pricebook2Id already in Contract layout (or bad fix was cleaned up)')

with open(contract_path, 'w', encoding='utf-8') as f:
    f.write(content)

# --- Fix 4: AccountBrand — add to forceignore if not already there ---
forceignore_path = '.forceignore'
entry = 'force-app/main/default/layouts/AccountBrand-Account Brand Layout.layout-meta.xml'
with open(forceignore_path, 'r', encoding='utf-8') as f:
    fi_content = f.read()
if entry not in fi_content:
    with open(forceignore_path, 'a', encoding='utf-8') as f:
        f.write(f'\n{entry}\n')
    print('Added AccountBrand layout to .forceignore')
else:
    print('AccountBrand already in .forceignore')
