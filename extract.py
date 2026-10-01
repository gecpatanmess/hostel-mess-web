import json
import os

transcript_path = r'C:\Users\daxpa\.gemini\antigravity\brain\22369819-24f7-4baa-beb4-c97dbc8bd93f\.system_generated\logs\transcript_full.jsonl'
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        if 'tool_calls' in data:
            for tc in data['tool_calls']:
                if tc['name'] == 'replace_file_content':
                    args = tc.get('args', {})
                    if 'main.dart' in args.get('TargetFile', ''):
                        print(f"Step {data.get('step_index')}: {args.get('toolSummary')}")
