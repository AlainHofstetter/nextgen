import os, re

LAYOUTS_DIR = os.path.join('force-app', 'main', 'default', 'layouts')

MISSING_FIELDS = [
    'Location.VisitorAddressId',
    'Package__c.ValPackageLockedInvoiceDraft__c',
    'Package__c.ValCountHasInvoiceDraft__c',
    'Package__c.BudgetOpenTotalSupplierCosts__c',
    'Package__c.BudgetOpenTotalTime__c',
    'Project__c.BudgetOpenForecastAmount__c',
]

for field in MISSING_FIELDS:
    obj, fieldname = field.split('.')
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
            print(f'Removed {field} from: {filename}')
