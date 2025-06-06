#!/bin/bash
cd "$(dirname "$0")"
git pull
source venv/bin/activate
python3 GameStock/sync_steam_games.py 