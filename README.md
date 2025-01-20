# BDD_Selenium_Python_Framework

### Using Docker

1. **Build Docker Image:**

   ```bash
    docker build -t bdd-selenium-image .

2. **Run Tests Inside Docker Container:**

   ```bash
    docker run --rm -v /features/reports/allure-report:/app/features/allure-report bdd-selenium-image