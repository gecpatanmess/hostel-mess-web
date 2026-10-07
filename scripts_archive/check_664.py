import json
transcript_path = r'C:\Users\daxpa\.gemini\antigravity\brain\22369819-24f7-4baa-beb4-c97dbc8bd93f\.system_generated\logs\transcript_full.jsonl'
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        step = data.get('step_index', 0)
        if step in [662, 663, 664, 665]:
            print(f"Step {step}: {data.get('type')}")
            if data.get('type') == 'PLANNER_RESPONSE':
                for tc in data.get('tool_calls', []):
                    print("Tool:", tc.get('name'))
