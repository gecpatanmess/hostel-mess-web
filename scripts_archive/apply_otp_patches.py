import json
import os

transcript_path = r'C:\Users\daxpa\.gemini\antigravity\brain\22369819-24f7-4baa-beb4-c97dbc8bd93f\.system_generated\logs\transcript_full.jsonl'
patches = []

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        if 'tool_calls' in data:
            for tc in data['tool_calls']:
                if tc['name'] == 'replace_file_content':
                    args = tc.get('args', {})
                    if 'main.dart' in args.get('TargetFile', ''):
                        patches.append({
                            'step': data.get('step_index'),
                            'summary': args.get('toolSummary'),
                            'target': args.get('TargetContent', ''),
                            'replacement': args.get('ReplacementContent', '')
                        })

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

for p in patches:
    print(f"Applying step {p['step']}: {p['summary']}")
    if p['target'] in content:
        content = content.replace(p['target'], p['replacement'])
        print(" -> SUCCESS")
    else:
        print(" -> FAILED: Target not found")
        # try removing carriage returns
        t2 = p['target'].replace('\r\n', '\n')
        c2 = content.replace('\r\n', '\n')
        if t2 in c2:
            print("    -> Found with LF instead of CRLF")
            content = c2.replace(t2, p['replacement'].replace('\r\n', '\n'))
        else:
            print("    -> Still not found")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
