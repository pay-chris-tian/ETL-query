-- 지정된 기간내에 최초로 인증서를 발급받은 유저의 건수
SELECT DATE_FORMAT(cu.issue_at, '%Y-%m') AS 발급_년월, COUNT(*) AS 신규_발급_건수
FROM pay_ra.certificate_user cu
WHERE cu.issue_at BETWEEN '시작일' AND '종료일'
  AND cu.pay_account_id NOT IN (
    SELECT pay_account_id 
    FROM pay_ra.certificate_user_history
  )
GROUP BY DATE_FORMAT(cu.issue_at, '%Y-%m')
ORDER BY 발급_년월;

-- 과거 발급된 모든 이력을 포함하여 pay_account_id 별로 조사
WITH AllCertificates AS (
    SELECT 
        pay_account_id,
        serial_number,
        issue_at,
        NULL AS revoked_at
    FROM 
        pay_ra.certificate_user
    UNION ALL
    SELECT 
        pay_account_id,
        serial_number,
        issue_at,
        revoked_at
    FROM 
        pay_ra.certificate_user_history
),
ReissuedCertificates AS (
    SELECT 
        ac1.pay_account_id, 
        ac1.serial_number, 
        ac1.issue_at,
        ac1.revoked_at
    FROM 
        AllCertificates ac1
    LEFT JOIN 
        AllCertificates ac2 
        ON ac1.pay_account_id = ac2.pay_account_id 
        AND ac1.issue_at > ac2.revoked_at
    WHERE 
        ac2.revoked_at IS NOT NULL
)
SELECT 
    DATE_FORMAT(rc.issue_at, '%Y-%m') AS 재발급_년월, 
    COUNT(*) AS 재발급_건수
FROM 
    ReissuedCertificates rc
GROUP BY 
    DATE_FORMAT(rc.issue_at, '%Y-%m')
ORDER BY 
    재발급_년월;

-- mysql 8.0 미만인 경우
SELECT 
    DATE_FORMAT(cu.issue_at, '%Y-%m') AS 재발급_년월, 
    COUNT(*) AS 재발급_건수
FROM 
    pay_ra.certificate_user cu
JOIN (
    SELECT 
        pay_account_id, 
        serial_number, 
        revoked_at
    FROM 
        pay_ra.certificate_user_history
) ec 
    ON cu.pay_account_id = ec.pay_account_id 
    AND cu.issue_at > ec.revoked_at
GROUP BY 
    DATE_FORMAT(cu.issue_at, '%Y-%m')
ORDER BY 
    재발급_년월;

-- 만료일이 지나지 않았는데 재발급된 건수를 찾는 쿼리
WITH ActiveCertificates AS (
    SELECT 
        cuh.pay_account_id, 
        cuh.serial_number, 
        cuh.revoked_at,
        cu.issue_at
    FROM 
        pay_ra.certificate_user_history cuh
    JOIN 
        pay_ra.certificate_user cu 
        ON cuh.pay_account_id = cu.pay_account_id
    WHERE 
        cu.issue_at < cuh.revoked_at
)
SELECT 
    DATE_FORMAT(ac.issue_at, '%Y-%m') AS 재발급_년월, 
    COUNT(*) AS 재발급_건수
FROM 
    ActiveCertificates ac
GROUP BY 
    DATE_FORMAT(ac.issue_at, '%Y-%m')
ORDER BY 
    재발급_년월;

-- mysql 8.0 미만
SELECT 
    DATE_FORMAT(cu.issue_at, '%Y-%m') AS 재발급_년월, 
    COUNT(*) AS 재발급_건수
FROM 
    pay_ra.certificate_user cu
JOIN (
    SELECT 
        pay_account_id, 
        serial_number, 
        revoked_at
    FROM 
        pay_ra.certificate_user_history
) cuh 
    ON cu.pay_account_id = cuh.pay_account_id 
    AND cu.issue_at < cuh.revoked_at
GROUP BY 
    DATE_FORMAT(cu.issue_at, '%Y-%m')
ORDER BY 
    재발급_년월;