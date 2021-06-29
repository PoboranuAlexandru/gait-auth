from flask_sqlalchemy import SQLAlchemy

global_db = SQLAlchemy()


class Users(global_db.Model):
    __tablename__ = 'Users'
    user_token = global_db.Column(global_db.String(5), primary_key=True)
    username = global_db.Column(global_db.String(100), nullable=False, unique=True)
    password = global_db.Column(global_db.String(100), nullable=False)
    is_logged_in = global_db.Column(global_db.Boolean, default=True)
    are_biometrics_ok = global_db.Column(global_db.Boolean, default=False)
