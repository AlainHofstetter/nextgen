import os, re

LAYOUTS_DIR = os.path.join('force-app', 'main', 'default', 'layouts')

# --- Fix 1: Contract layout — remove our bad Pricebook2Id insertion and fix structure ---
contract_path = os.path.join(LAYOUTS_DIR, 'Contract-Contract Layout.layout-meta.xml')
with open(contract_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the badly nested layoutItem block we inserted
bad_block = re.compile(
    r'<layoutItems>\s*\n\s*<layoutItem>\s*\n\s*<field>Pricebook2Id</field>\s*\n\s*</layoutItem>\s*\n\s*<emptySpace>true</emptySpace>\s*\n\s*</layoutItems>',
    re.MULTILINE
)
# Replace with a proper standalone layoutItems block before the existing ones
if bad_block.search(content):
    content = bad_block.sub(
        '<layoutItems>\n                <behavior>Edit</behavior>\n                <field>Pricebook2Id</field>\n            </layoutItems>\n            <layoutItems>\n                <emptySpace>true</emptySpace>\n            </layoutItems>',
        content
    )
    with open(contract_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Fixed: Contract-Contract Layout — Pricebook2Id structure corrected')
else:
    print('Pattern not found in Contract layout — check manually')

# --- Fix 2: Remove missing fields (with or without <behavior> tag) ---
MISSING_FIELDS = [
    'VisitorAddressId',
    'ValPackageLockedInvoiceDraft__c',
    'ValCountHasInvoiceDraft__c',
    'BudgetOpenTotalSupplierCosts__c',
    'BudgetOpenTotalTime__c',
    'BudgetOpenForecastAmount__c',
]

for fieldname in MISSING_FIELDS:
    # Match layoutItems block containing this field (with or without behavior)
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
            print(f'Removed field [{fieldname}] from: {filename}')
