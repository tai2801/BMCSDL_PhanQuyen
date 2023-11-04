# ERD — SECUREDB (Mermaid)

```mermaid
erDiagram
    ROLES ||--o{ APP_USERS : "co"
    STUDENTS ||--o| APP_USERS : "tai khoan cua"
    LECTURERS ||--o| APP_USERS : "tai khoan cua"
    LECTURERS ||--o{ CLASSES : "duoc phan cong day"
    COURSES ||--o{ CLASSES : "mo lop"
    CLASSES ||--o{ ENROLLMENTS : "co"
    STUDENTS ||--o{ ENROLLMENTS : "dang ky"
    ENROLLMENTS ||--|| GRADES : "co diem"
    GRADES ||--o{ GRADE_AUDIT_LOG : "lich su sua"
    APP_USERS {
        int user_id PK
        nvarchar username UK
        nvarchar password_hash "BCrypt"
        int role_id FK
        int student_id FK
        int lecturer_id FK
        int failed_login_count
        datetime2 locked_until
    }
    STUDENTS {
        int student_id PK
        nvarchar student_code UK
        nvarchar full_name
        varbinary phone_enc "ma hoa"
        varbinary national_id_enc "ma hoa"
    }
    GRADES {
        int grade_id PK
        int enrollment_id FK_UK
        decimal process_score
        decimal final_score
        decimal total_score "computed 0.4/0.6"
    }
```
