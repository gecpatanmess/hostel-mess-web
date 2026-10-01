import json
with open(r'C:\Users\daxpa\.gemini\antigravity\brain\22369819-24f7-4baa-beb4-c97dbc8bd93f\.system_generated\logs\transcript_full.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        if data.get('step_index') in [72, 78, 82, 98, 160, 164]:
            if 'tool_calls' in data and len(data['tool_calls']) > 0:
                tc = data['tool_calls'][0].get('args', {})
                print(f"--- Step {data['step_index']} ---")
                print("TARGET:")
                print(tc.get('TargetContent', ''))
