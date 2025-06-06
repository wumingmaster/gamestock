from Models.models import db, Game

log(f'Game: id={game.id}, steam_id={getattr(game, "steam_id", None)}, name={game.name}') 