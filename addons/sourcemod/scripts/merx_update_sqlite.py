import keyvalues
import sqlite3
import os

def get_database_info(databases):
    if "merx" in databases:
        database = "merx"
    else:
        database = "default"
    driver = databases[database]["driver"]
    if driver == "default":
        driver = databases["driver_default"]
    return databases[database], driver

kv = keyvalues.keyvalues()
kv.load_from_file("../configs/databases.cfg")
database, driver = get_database_info(kv.kv["Databases"])
if driver != "sqlite":
    print("Invalid database info: This script is only for sqlite databases. If you are using sqlite please ensure that your databases.cfg is setup properly.")
else:
    path = "../data/sqlite/" + database["database"] + ".sq3"
    if os.path.isfile(path):
        with sqlite3.connect(path) as conn:
            try:
                c = conn.cursor()
                c.execute("""ALTER TABLE `merx_players` ADD COLUMN `player_total_points` INT NOT NULL DEFAULT 0;""")
                c.close()
                print("Update succeeded. Restart your server.")
            except:
                print("Failed to update database, it has either already been updated or hasn't been created.")
    else:
        print("Invalid database info: {} does not exist, please check your databases.cfg.".format(os.path.abspath(path)))
input()
