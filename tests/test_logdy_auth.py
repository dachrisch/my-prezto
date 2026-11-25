#!/usr/bin/env python3
"""logdy must read its Loki endpoint and credentials from Ansible's 0600 env file.

Since 2026-11-20 Loki lives on codey behind basic auth; a bare X-Scope-OrgID
header gets a 302. The public dotfiles repo must hold no credentials: they are
rendered into ~/.config/logdy/loki.env and sourced here. The stale LOKI_URL
export in zshenv must not win.
"""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOGDY = ROOT / "custom/functions/logdy"

FAKE_CURL = """#!/bin/sh
printf '%s\\n' "$@" > "$CURL_ARGS_CAPTURE"
printf '204'
"""

ENV_FILE = (
    'LOKI_URL="http://loki.test/loki/api/v1/push"\n'
    'LOKI_USER="pushuser"\n'
    'LOKI_PASSWORD="pushsecret"\n'
    'LOKI_TENANT_ID="tenant-abc"\n'
)


class LogdyLokiAuth(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        (root / "bin").mkdir()
        (root / "bin/curl").write_text(FAKE_CURL)
        (root / "bin/curl").chmod(0o755)
        (root / ".config/logdy").mkdir(parents=True)
        (root / ".config/logdy/loki.env").write_text(ENV_FILE)
        self.args = root / "curl-args.txt"
        self.env = dict(os.environ)
        self.env.update(
            HOME=str(root),
            PATH=f"{root / 'bin'}:{self.env['PATH']}",
            CURL_ARGS_CAPTURE=str(self.args),
            LOGDY_SILENT="1",
            # Simulates the old zshenv export: it must be overridden.
            LOKI_URL="https://monitor.lehel.xyz/loki/api/v1/push",
            LOKI_API_KEY="stale-tenant",
        )

    def run_logdy(self):
        proc = subprocess.run(
            ["zsh", "-c", f"source {LOGDY}; logdy info 'auth test' key=value"],
            env=self.env, capture_output=True, text=True, timeout=30,
        )
        return proc, self.args.read_text().splitlines() if self.args.exists() else []

    def test_env_file_supplies_endpoint_user_password_and_tenant(self):
        proc, args = self.run_logdy()
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("http://loki.test/loki/api/v1/push", args, args)
        self.assertIn("pushuser:pushsecret", args, args)
        self.assertIn("X-Scope-OrgID: tenant-abc", args, args)
        self.assertFalse(any("monitor.lehel.xyz" in a for a in args), args)

    def test_no_hardcoded_endpoint_in_the_function(self):
        self.assertNotIn("monitor.lehel.xyz", LOGDY.read_text())


if __name__ == "__main__":
    unittest.main()
