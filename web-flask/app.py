"""Entry point aplikasi GlucoSafe Flask."""

import os
from dotenv import load_dotenv

from glucosafe import create_app

load_dotenv()

app = create_app()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_DEBUG", "0") in ("1", "true", "True")
    app.run(host="0.0.0.0", port=port, debug=debug)
