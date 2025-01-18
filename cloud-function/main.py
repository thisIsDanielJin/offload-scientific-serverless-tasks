import csv
import json
from flask import Request

def convert_csv_to_json(request: Request):
    """
    Erwartet einen POST-Request mit JSON-Body nach folgendem Schema:
    {
        "csv_data": "name,age\nDaniel,24\nTom,42\nMaria,18"
    }

    => Gibt JSON zurück, z.B.:
    [
        {"name": "Daniel", "age": "24"},
        {"name": "Tom", "age": "42"},
        {"name": "Maria", "age": "18"}
    ]
    """
    try:
        # Request-Body als JSON parsen
        request_json = request.get_json()
        if not request_json or "csv_data" not in request_json:
            return ("Fehler: 'csv_data' fehlt im Request-Body.", 400)

        csv_data = request_json["csv_data"]
        # CSV-Daten splitten in Zeilen
        lines = csv_data.splitlines()
        # CSV via DictReader parsen (erwartet erste Zeile als Header)
        reader = csv.DictReader(lines)
        data = [row for row in reader]

        # JSON-Response erzeugen
        return (
            json.dumps(data, ensure_ascii=False), 
            200,
            {"Content-Type": "application/json"}
        )

    except Exception as e:
        error_msg = f"Fehler beim Konvertieren: {str(e)}"
        return (error_msg, 500)
