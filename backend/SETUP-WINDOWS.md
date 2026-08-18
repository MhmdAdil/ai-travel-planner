# Windows development setup

The project supports both MySQL 8 and the MariaDB server supplied with XAMPP.

## XAMPP MariaDB on port 3307

Start **MySQL** in XAMPP. In a new Command Prompt, run each command separately:

```text
cd /d "C:\Users\adilm\Projects\ai-travel-planner\backend"
```

```text
set "DB_URL=jdbc:mariadb://localhost:3307/ai_travel_planner?createDatabaseIfNotExist=true"
```

```text
set "DB_USERNAME=root"
```

```text
set "DB_PASSWORD="
```

```text
set "JWT_SECRET=adil-ai-travel-planner-development-secret-2026"
```

The USD value is approximate and uses a configurable LKR-per-USD rate. For example:

```text
set "LKR_PER_USD=310.00"
```

Run tests and start the API:

```text
mvn test
```

```text
mvn spring-boot:run
```

Keep that window open. In a second Command Prompt:

```text
cd /d "C:\Users\adilm\Projects\ai-travel-planner"
```

```text
flutter pub get
```

```text
flutter test
```

```text
flutter run
```

The Android emulator connects to the Windows backend through `http://10.0.2.2:8080`.
