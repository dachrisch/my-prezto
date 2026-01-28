# Standalone Gemini Usage Tool

This directory contains a self-contained version of the Gemini usage fetcher.

## Installation

```bash
npm install
```

## Usage

```bash
# Human readable output
node index.js

# Concise output (model, percentage, reset)
node index.js -s

# JSON output for jq
node index.js --json | jq
```
