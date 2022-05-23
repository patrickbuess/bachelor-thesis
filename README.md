# Bachelor thesis code repository
This repository contains the code for the bachelor thesis on the subject "Do elections influence international relations".

## Following are the instructions to run the project locally
(Make sure the .env file is existing, filled out, and placed in the root level. Check the .env.sample file for guidance.)

### To restore the database locally do the following:
- Retrieve the sql backup file from the link provided in the thesis (or use the reduced set in _data/backup/)
- Make sure the backup file is stored in the folder _data/backup/
- Start the db container via `docker-compose run db`
- Enter the docker container via `docker exec -it <USA CONTAINER NAME> /bin/bash`
- Restore the file from inside the container via `psql -U db_user -d ba_db < backup/filename.sql` (your db credentials may vary)

### To run parts of the code
- To create a python shell: `docker-compose run shell`
- Retrieve all GDELT Data: `docker-compose run collect_gdelt`
- Load, process, and insert countries: `docker-compose run handle_countries`
- Load, process, and insert elections: `docker-compose run handle_elections`
- Process GDELT data: `docker-compose run handle_gdelt_all`
- Run automated regression code: `docker-compose run analyse_regression`