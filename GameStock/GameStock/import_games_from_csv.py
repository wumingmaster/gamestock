steam_id = str(row['appid'])
name = row['name']
# ... 其他字段 ...
game = Game.query.filter_by(steam_id=steam_id).first()
if not game:
    game = Game(steam_id=steam_id, name=name) 