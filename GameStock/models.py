from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    steam_id = db.Column(db.String(20), unique=True, nullable=False)
    name = db.Column(db.String(200), nullable=False)
    name_zh = db.Column(db.String(200))
    sales_count = db.Column(db.Integer)
    positive_reviews = db.Column(db.Integer)
    total_reviews = db.Column(db.Integer)
    current_price = db.Column(db.Float)
    last_updated = db.Column(db.DateTime)
    icon_url = db.Column(db.String(500))
    header_image = db.Column(db.String(500))
    data_accuracy = db.Column(db.String(20))
    api_status = db.Column(db.String(50)) 