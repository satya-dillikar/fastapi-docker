## Prerequisite
- Create a docker account
- setup virtual env (if required)

## Steps
- cp env_sample .env
- update .env with your values
- add your code in app/ folder
- update docker-compose.yaml (if required)
- update requirements.txt as needed by code in app/ folder
- use make commands like
    - make up
    - make down
    - make restart
    - make push
    - make build
    - make push
    - make remove
