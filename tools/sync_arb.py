import os
import json

def main():
    l10n_dir = 'lib/app/l10n'
    en_path = os.path.join(l10n_dir, 'app_en.arb')
    
    if not os.path.exists(en_path):
        print(f"Error: English ARB not found at {en_path}")
        return
        
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
        
    # Get all keys in app_en.arb
    en_keys = list(en_data.keys())
    
    # Process other files
    for filename in sorted(os.listdir(l10n_dir)):
        if not filename.endswith('.arb') or filename == 'app_en.arb':
            continue
            
        file_path = os.path.join(l10n_dir, filename)
        locale_code = filename.replace('app_', '').replace('.arb', '')
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        updated_data = {}
        # Ensure @@locale is first and correctly set
        updated_data['@@locale'] = locale_code
        
        # Merge keys in the exact order of app_en.arb
        for key in en_keys:
            if key == '@@locale':
                continue
            if key in data:
                updated_data[key] = data[key]
            else:
                updated_data[key] = en_data[key]
                
        # Write back sorted/synced JSON
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(updated_data, f, ensure_ascii=False, indent=2)
            f.write('\n')
            
        print(f"Synced {filename}")

if __name__ == '__main__':
    main()
