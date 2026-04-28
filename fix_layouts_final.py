import os, re

LAYOUTS_DIR = os.path.join('force-app', 'main', 'default', 'layouts')

# --- Fix 1: Contract-Contract Layout — add Pricebook2Id field ---
contract_path = os.path.join(LAYOUTS_DIR, 'Contract-Contract Layout.layout-meta.xml')
with open(contract_path, 'r', encoding='utf-8') as f:
    content = f.read()
# Insert Pricebook2Id into the first layoutSection's layoutColumns/layoutItems
if 'Pricebook2Id' not in content:
    # Add it before the first </layoutItems> closing tag
    content = content.replace('</layoutItems>', '</layoutItems>\n        <layoutItem>\n            <field>Pricebook2Id</field>\n        </layoutItem>', 1)
    with open(contract_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Fixed: Contract-Contract Layout — added Pricebook2Id')
else:
    print('Pricebook2Id already present in Contract layout')

# --- Fix 2: Quote-Quote Layout — remove Add_Packages_For_Quote references ---
quote_path = os.path.join(LAYOUTS_DIR, 'Quote-Quote Layout.layout-meta.xml')
with open(quote_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove <customButtons>Add_Packages_For_Quote</customButtons>
content = re.sub(r'\s*<customButtons>Add_Packages_For_Quote</customButtons>', '', content)

# Remove platformActionListItems block with Add_Packages_For_Quote
content = re.sub(
    r'\s*<platformActionListItems>\s*<actionName>Add_Packages_For_Quote</actionName>.*?</platformActionListItems>',
    '', content, flags=re.DOTALL
)

# Remove quickActionListItems block with Quote.Add_Packages_for_Quote
content = re.sub(
    r'\s*<quickActionListItems>\s*<quickActionName>Quote\.Add_Packages_for_Quote</quickActionName>\s*</quickActionListItems>',
    '', content
)

with open(quote_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed: Quote-Quote Layout — removed Add_Packages_For_Quote references')

# --- Fix 3: User-User Layout — remove IndividualId relatedObjects ---
user_path = os.path.join(LAYOUTS_DIR, 'User-User Layout.layout-meta.xml')
with open(user_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'\s*<relatedObjects>IndividualId</relatedObjects>', '', content)

with open(user_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed: User-User Layout — removed IndividualId')
