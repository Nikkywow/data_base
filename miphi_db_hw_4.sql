--Задачи 1

WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: Иван Иванов (EmployeeID = 1)
    SELECT 
        e.EmployeeID,
        e.Name AS EmployeeName,
        e.ManagerID,
        d.DepartmentName,
        r.RoleName,
        ARRAY[e.EmployeeID] AS path
    FROM Employees e
    JOIN Departments d ON e.DepartmentID = d.DepartmentID
    JOIN Roles r ON e.RoleID = r.RoleID
    WHERE e.EmployeeID = 1
    
    UNION ALL
    
    -- Рекурсивный случай: все подчиненные
    SELECT 
        e.EmployeeID,
        e.Name AS EmployeeName,
        e.ManagerID,
        d.DepartmentName,
        r.RoleName,
        eh.path || e.EmployeeID
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
    JOIN Departments d ON e.DepartmentID = d.DepartmentID
    JOIN Roles r ON e.RoleID = r.RoleID
    WHERE NOT e.EmployeeID = ANY(eh.path) -- Предотвращаем циклические ссылки
)

SELECT 
    eh.EmployeeID,
    eh.EmployeeName,
    eh.ManagerID,
    eh.DepartmentName,
    eh.RoleName,
    (SELECT STRING_AGG(p.ProjectName, ', ' ORDER BY p.ProjectName)
     FROM Projects p
     JOIN Tasks t ON p.ProjectID = t.ProjectID
     WHERE t.AssignedTo = eh.EmployeeID) AS ProjectNames,
    (SELECT STRING_AGG(t.TaskName, ', ' ORDER BY t.TaskName)
     FROM Tasks t
     WHERE t.AssignedTo = eh.EmployeeID) AS TaskNames
FROM EmployeeHierarchy eh
ORDER BY eh.EmployeeName;

--Задача 2

WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: Иван Иванов (EmployeeID = 1)
    SELECT 
        e.EmployeeID,
        e.Name AS EmployeeName,
        e.ManagerID,
        d.DepartmentName,
        r.RoleName,
        ARRAY[e.EmployeeID] AS path
    FROM Employees e
    JOIN Departments d ON e.DepartmentID = d.DepartmentID
    JOIN Roles r ON e.RoleID = r.RoleID
    WHERE e.EmployeeID = 1
    
    UNION ALL
    
    -- Рекурсивный случай: все подчиненные
    SELECT 
        e.EmployeeID,
        e.Name AS EmployeeName,
        e.ManagerID,
        d.DepartmentName,
        r.RoleName,
        eh.path || e.EmployeeID
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
    JOIN Departments d ON e.DepartmentID = d.DepartmentID
    JOIN Roles r ON e.RoleID = r.RoleID
    WHERE NOT e.EmployeeID = ANY(eh.path)
),

EmployeeTasks AS (
    SELECT 
        eh.EmployeeID,
        eh.EmployeeName,
        eh.ManagerID,
        eh.DepartmentName,
        eh.RoleName,
        (SELECT STRING_AGG(p.ProjectName, ', ' ORDER BY p.ProjectName)
         FROM Projects p
         JOIN Tasks t ON p.ProjectID = t.ProjectID
         WHERE t.AssignedTo = eh.EmployeeID) AS ProjectNames,
        (SELECT STRING_AGG(t.TaskName, ', ' ORDER BY t.TaskName)
         FROM Tasks t
         WHERE t.AssignedTo = eh.EmployeeID) AS TaskNames,
        (SELECT COUNT(*) FROM Tasks t WHERE t.AssignedTo = eh.EmployeeID) AS TotalTasks
    FROM EmployeeHierarchy eh
),

SubordinateCount AS (
    SELECT 
        e.ManagerID,
        COUNT(*) AS TotalSubordinates
    FROM Employees e
    GROUP BY e.ManagerID
)

SELECT 
    et.EmployeeID,
    et.EmployeeName,
    et.ManagerID,
    et.DepartmentName,
    et.RoleName,
    et.ProjectNames,
    et.TaskNames,
    et.TotalTasks,
    COALESCE(sc.TotalSubordinates, 0) AS TotalSubordinates
FROM EmployeeTasks et
LEFT JOIN SubordinateCount sc ON et.EmployeeID = sc.ManagerID
ORDER BY et.EmployeeName;

--Задача 3

WITH RECURSIVE ManagerHierarchy AS (
    -- Базовый случай: все менеджеры с подчиненными
    SELECT 
        e.EmployeeID,
        e.Name AS EmployeeName,
        e.ManagerID,
        d.DepartmentName,
        r.RoleName,
        ARRAY[e.EmployeeID] AS path
    FROM Employees e
    JOIN Departments d ON e.DepartmentID = d.DepartmentID
    JOIN Roles r ON e.RoleID = r.RoleID
    WHERE r.RoleName = 'Менеджер'
      AND EXISTS (SELECT 1 FROM Employees WHERE ManagerID = e.EmployeeID)
    
    UNION ALL
    
    -- Рекурсивный случай: находим всех подчиненных менеджеров
    SELECT 
        e.EmployeeID,
        e.Name AS EmployeeName,
        e.ManagerID,
        d.DepartmentName,
        r.RoleName,
        mh.path || e.EmployeeID
    FROM Employees e
    JOIN ManagerHierarchy mh ON e.ManagerID = mh.EmployeeID
    JOIN Departments d ON e.DepartmentID = d.DepartmentID
    JOIN Roles r ON e.RoleID = r.RoleID
    WHERE NOT e.EmployeeID = ANY(mh.path)
),

ManagerWithSubordinates AS (
    -- Основные менеджеры (те, у кого есть подчиненные)
    SELECT DISTINCT ON (m.EmployeeID)
        m.EmployeeID,
        m.EmployeeName,
        m.ManagerID,
        m.DepartmentName,
        m.RoleName,
        (SELECT COUNT(*) 
         FROM Employees e 
         WHERE e.ManagerID = m.EmployeeID) AS DirectSubordinates,
        (SELECT COUNT(*) 
         FROM ManagerHierarchy mh 
         WHERE mh.path[1] = m.EmployeeID) - 1 AS TotalSubordinates
    FROM ManagerHierarchy m
    WHERE array_length(m.path, 1) = 1  -- Только начальные менеджеры
),

ManagerProjectsTasks AS (
    SELECT 
        m.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames
    FROM ManagerWithSubordinates m
    LEFT JOIN Tasks t ON t.AssignedTo = m.EmployeeID
    LEFT JOIN Projects p ON t.ProjectID = p.ProjectID
    GROUP BY m.EmployeeID
)

SELECT 
    m.EmployeeID,
    m.EmployeeName,
    m.ManagerID,
    m.DepartmentName,
    m.RoleName,
    mt.ProjectNames,
    mt.TaskNames,
    m.TotalSubordinates
FROM ManagerWithSubordinates m
JOIN ManagerProjectsTasks mt ON m.EmployeeID = mt.EmployeeID
ORDER BY m.TotalSubordinates DESC;