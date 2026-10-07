
$jsonl = "C:\Users\daxpa\.gemini\antigravity\brain\e95c5d43-5db7-4448-b2ea-8e9ea4d76354\.system_generated\logs\transcript_full.jsonl"
$lines = Get-Content $jsonl
foreach ($line in $lines) {
    if ($line -match "exportReport") {
        # ...
    }
}

