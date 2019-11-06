CREATE OR REPLACE PACKAGE BODY TT_HR_PASS."NWKPASS" IS
/******************************************************************************
   NAME:       NWKPASS              
   
   PURPOSE:
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        6/8/2017      calugolu       1. Created this package body. Modified today.     
******************************************************************************/
                         
 --------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_transaction_no
-- PRODUCT....: HR
-- USAGE......: Increment and return ID seq
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return a generic id for new position             
--------------------------------------------------------------------------------------------

FUNCTION f_get_np_transaction_no
RETURN NUMBER
  AS tmpVar NUMBER;

BEGIN
   tmpVar := 0;
   select tt_hr_pass.nc_pass_np_trans_no_b_sq.nextval into tmpVar from dual;
   RETURN tmpVar;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       RAISE;
END f_get_np_transaction_no;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_rc_transaction_no
-- PRODUCT....: HR
-- USAGE......: Increment and return ID seq of reclassification
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return a generic id for reclassification
--------------------------------------------------------------------------------------------

FUNCTION f_get_rc_transaction_no
RETURN NUMBER
  AS tmpVar NUMBER;

BEGIN
   tmpVar := 0;
   select tt_hr_pass.nc_pass_rc_trans_no_b_sq.nextval into tmpVar from dual;
   RETURN tmpVar;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       RAISE;
END f_get_rc_transaction_no;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_sr_transaction_no
-- PRODUCT....: HR
-- USAGE......: Increment and return ID seq of salary review
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return a generic id for salary review
--------------------------------------------------------------------------------------------

FUNCTION f_get_sr_transaction_no
RETURN NUMBER
  AS tmpVar NUMBER;

BEGIN
   tmpVar := 0;
   select tt_hr_pass.nc_pass_sr_trans_no_b_sq.nextval into tmpVar from dual;
   RETURN tmpVar;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       RAISE;
END f_get_sr_transaction_no;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_active_employee_list
-- PRODUCT....: HR
-- USAGE......: Display a list of active employees who have an active job
--              as of today that is not a retiree position. 
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return a list of active employees 
--------------------------------------------------------------------------------------------

FUNCTION f_get_active_employee_list
   RETURN SYS_REFCURSOR
AS
   c_empl_list  SYS_REFCURSOR;

BEGIN

   OPEN c_empl_list FOR

     SELECT distinct spriden_id,spriden_pidm,spriden_first_name, spriden_last_name,spriden_mi       
  FROM spriden, nbrjobs t1, nbrbjob
 WHERE     spriden_change_ind IS NULL           
       AND t1.nbrjobs_pidm = spriden_pidm
       AND t1.nbrjobs_status = 'A'
       AND t1.nbrjobs_ecls_code NOT IN ('M1', 'M2')
       AND nbrbjob_pidm = t1.nbrjobs_pidm
       AND nbrbjob_posn = t1.nbrjobs_posn
       AND nbrbjob_suff = t1.nbrjobs_suff
       AND (nbrbjob_end_date IS NULL OR nbrbjob_end_date >= SYSDATE)
       AND nbrbjob_contract_type IN ('P', 'S')
       AND t1.nbrjobs_effective_date =
              (SELECT MAX (nbrjobs_effective_date)
                 FROM nbrjobs t11
                WHERE     t11.nbrjobs_pidm = t1.nbrjobs_pidm
                      AND t11.nbrjobs_posn = t1.nbrjobs_posn
                      AND t11.nbrjobs_suff = t1.nbrjobs_suff
                      AND t11.nbrjobs_effective_date <= SYSDATE);   

   RETURN c_empl_list;

END f_get_active_employee_list;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: getAnalystAssigned
-- PRODUCT....: HR
-- USAGE......: Get Analyst assigned for an Orgn
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return a list of analysts assigned for the given chart code and orgn code
--------------------------------------------------------------------------------------------
FUNCTION getAnalystAssigned(chartCode VARCHAR2, Orgn VARCHAR2) RETURN SYS_REFCURSOR AS
        c_ANALYST SYS_REFCURSOR;
        BEGIN
            OPEN c_ANALYST FOR
                SELECT ID AS ID,
                       RNUM AS RNUM,
                       BEGIN_ORGN AS BEGIN_ORGN,
                       END_ORGN AS END_ORGN
                  FROM TT_HR_PASS.NC_PASS_FUNCUSRASSIGN_C
                  WHERE COAS_CODE = chartCode AND Orgn
                  BETWEEN  BEGIN_ORGN AND END_ORGN;
        RETURN c_ANALYST;
        END getAnalystAssigned;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_getPassRequestByDateRange
-- PRODUCT....: HR
-- USAGE......: Get request by date range for PASS
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will join Transaction table with pwvorgn and FWVATUE to return originator and employee details and org title for PASS application.
--------------------------------------------------------------------------------------------
FUNCTION f_getPassRequestByDateRange(startDate DATE, endDate DATE , oracleID varchar2 ,originatorPidm INTEGER) RETURN SYS_REFCURSOR AS c_nc_pass_trans_b SYS_REFCURSOR;
        BEGIN
            OPEN c_nc_pass_trans_b FOR
    SELECT DISTINCT T1.TRANS_ID, T1.TRANS_NO, T1.TRANS_STATUS,T1.ORIGINATOR_PIDM,T1.ORIGINATOR_POSN, T1.ORIGINATOR_ORGN_CODE_HOME,T1.POSN_NBR,T1.POSN_COAS_CODE,
         TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
          t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
         JOIN TTUFISCAL.FWVORGN T6 ON T1.POSN_ORGN_CODE = ORGANIZATION_LEVEL_7
         JOIN NSRSPSC T5 on (T5.NSRSPSC_USER_CODE = oracleID and T6.ORGANIZATION_LEVEL_5 = T5.NSRSPSC_ORGN_CODE and T1.POSN_COAS_CODE = T5.NSRSPSC_COAS_CODE)
       WHERE trunc(T1.POSN_EFFECTIVE_DATE) >= trunc(startDate)
                  AND trunc(T1.POSN_EFFECTIVE_DATE) <= trunc(endDate)
                  AND ORIGINATOR_PIDM != originatorPidm 
                  AND T1.POSN_COAS_CODE IN ('H','E')
                   UNION ALL
    SELECT DISTINCT T1.TRANS_ID, T1.TRANS_NO, T1.TRANS_STATUS,T1.ORIGINATOR_PIDM,T1.ORIGINATOR_POSN, T1.ORIGINATOR_ORGN_CODE_HOME,T1.POSN_NBR,T1.POSN_COAS_CODE,
          TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
          t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
         JOIN TTUFISCAL.FWVORGN T6 ON T1.POSN_ORGN_CODE = ORGANIZATION_LEVEL_7
         JOIN NSRSPSC T5 on (T5.NSRSPSC_USER_CODE = oracleID and (T6.ORGANIZATION_LEVEL_5 = T5.NSRSPSC_ORGN_CODE OR T6.ORGANIZATION_LEVEL_7 = T5.NSRSPSC_ORGN_CODE) and T1.POSN_COAS_CODE = T5.NSRSPSC_COAS_CODE)
       WHERE trunc(T1.POSN_EFFECTIVE_DATE) >= trunc(startDate)
                  AND trunc(T1.POSN_EFFECTIVE_DATE) <= trunc(endDate)
                  AND ORIGINATOR_PIDM != originatorPidm 
                  AND T1.POSN_COAS_CODE IN ('T','S')
            UNION  ALL       
    SELECT DISTINCT T1.TRANS_ID, T1.TRANS_NO, T1.TRANS_STATUS,T1.ORIGINATOR_PIDM,T1.ORIGINATOR_POSN, T1.ORIGINATOR_ORGN_CODE_HOME,T1.POSN_NBR,T1.POSN_COAS_CODE,
         TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
          t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
       WHERE trunc(T1.POSN_EFFECTIVE_DATE) >= trunc(startDate)
                  AND trunc(T1.POSN_EFFECTIVE_DATE) <= trunc(endDate)
                  AND originator_pidm = originatorPidm;
            RETURN c_nc_pass_trans_b;
        END f_getPassRequestByDateRange;
        
--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_getPassAdminRequest
-- PRODUCT....: HR
-- USAGE......: Get request by date range for PASS Admins
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will join Transaction table with pwvorgn and FWVATUE to return originator and employee details and org title for PASS application.
--------------------------------------------------------------------------------------------
FUNCTION f_getPassAdminRequest(startDate DATE, endDate DATE , chart varchar2 ,originatorPidm INTEGER) RETURN SYS_REFCURSOR AS c_nc_pass_trans_b SYS_REFCURSOR;
        BEGIN
            OPEN c_nc_pass_trans_b FOR
    SELECT T1.TRANS_NO, T1.TRANS_STATUS, T1.POSN_NBR,T1.POSN_COAS_CODE,
          TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
          t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
         WHERE trunc(T1.POSN_EFFECTIVE_DATE) >= trunc(startDate)
                  AND trunc(T1.POSN_EFFECTIVE_DATE) <= trunc(endDate)
                  AND ORIGINATOR_PIDM != originatorPidm 
                  AND T1.POSN_COAS_CODE IN
               (SELECT regexp_substr(chart, '[^,]+', 1, LEVEL)
                FROM   dual
                CONNECT BY regexp_substr(chart, '[^,]+', 1, LEVEL) IS NOT NULL)
            UNION  ALL       
    SELECT T1.TRANS_NO, T1.TRANS_STATUS, T1.POSN_NBR,T1.POSN_COAS_CODE,
          TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
          t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
       WHERE trunc(T1.POSN_EFFECTIVE_DATE) >= trunc(startDate)
                  AND trunc(T1.POSN_EFFECTIVE_DATE) <= trunc(endDate)
                  AND originator_pidm = originatorPidm;
            RETURN c_nc_pass_trans_b;
        END f_getPassAdminRequest;        
        
--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_getPassRequestByID
-- PRODUCT....: HR
-- USAGE......: Get request by originator pidm for PASS
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will join Transaction table with pwvorgn  and FWVATUE to return originator and employee details and org title for PASS application based on originator pidm.
--------------------------------------------------------------------------------------------

FUNCTION f_getPassRequestByID(originatorPidm INTEGER) RETURN SYS_REFCURSOR AS c_nc_pass_trans_b SYS_REFCURSOR;
        BEGIN
            OPEN c_nc_pass_trans_b FOR
    SELECT T1.TRANS_NO, T1.TRANS_STATUS, T1.POSN_NBR,T1.POSN_COAS_CODE,
          TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
         t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
      WHERE T1.ORIGINATOR_PIDM = originatorPidm
    ORDER BY T1.CREATE_DATE ASC;
    RETURN c_nc_pass_trans_b;
   END f_getPassRequestByID;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_bavl_ctrl_table
-- PRODUCT....: HR
-- USAGE......: Check BAVL control table for this fund
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return either error or warning for fund selected.
--------------------------------------------------------------------------------------------

function f_check_bavl_ctrl_table(
     chart varchar2,
     fund varchar2)
     return varchar2
  as
     bavlError varchar2(20) default null;
     level5 number := 0;
     level1 number := 0;
     bavlerrorlevel5 number := 0;
     bavlerrorlevel1 number := 0;
     bavlerrorfundtype number := 0;

BEGIN

SELECT COUNT (*)
     INTO LEVEL5
     FROM TT_HR_PASS.NC_PASS_BAVLERR_C
    WHERE COAS_CODE = chart AND LEVEL5_FUND = fund AND STATUS = 'A';

   IF (LEVEL5 > 0)
   THEN
      SELECT COUNT (*)
        INTO BAVLERRORLEVEL5
        FROM TT_HR_PASS.NC_PASS_BAVLERR_C
       WHERE     COAS_CODE = chart
             AND LEVEL5_FUND = fund
             AND STATUS = 'A'
             AND ERRTYPE = 'E';

      IF (BAVLERRORLEVEL5 > 0)
      THEN
         SELECT ERRTYPE
           INTO BAVLERROR
           FROM TT_HR_PASS.NC_PASS_BAVLERR_C
          WHERE     COAS_CODE = chart
                AND LEVEL5_FUND = fund
                AND STATUS = 'A'
                AND ERRTYPE = 'E'
                AND ROWNUM = 1;
      ELSE
         SELECT ERRTYPE
           INTO BAVLERROR
           FROM TT_HR_PASS.NC_PASS_BAVLERR_C
          WHERE     COAS_CODE = chart
                AND LEVEL5_FUND = fund
                AND STATUS = 'A'
                AND ERRTYPE = 'W'
                AND ROWNUM = 1;
      END IF;
   ELSE
      SELECT COUNT (*)
        INTO LEVEL1
        FROM TT_HR_PASS.NC_PASS_BAVLERR_C
       WHERE     COAS_CODE = chart
             AND STATUS = 'A'
             AND LEVEL5_FUND IS NULL
             AND LEVEL1_FUND = (SELECT TT_GRANT.YWKFINC.F_GET_FUND_HIER (
                                          '',
                                          chart,
                                          fund,
                                          SYSDATE,
                                          1,
                                          'CODE')
                                  FROM DUAL);

      IF (LEVEL1 > 0)
      THEN
         SELECT COUNT (*)
           INTO BAVLERRORLEVEL1
           FROM TT_HR_PASS.NC_PASS_BAVLERR_C
          WHERE     ERRTYPE = 'E'
                AND COAS_CODE = chart
                AND STATUS = 'A'
                AND LEVEL5_FUND IS NULL
                AND LEVEL1_FUND = (SELECT TT_GRANT.YWKFINC.F_GET_FUND_HIER (
                                             '',
                                             chart,
                                             fund,
                                             SYSDATE,
                                             1,
                                             'CODE')
                                     FROM DUAL);


         IF (BAVLERRORLEVEL1 > 0)
         THEN
            SELECT ERRTYPE
              INTO BAVLERROR
              FROM TT_HR_PASS.NC_PASS_BAVLERR_C
             WHERE     COAS_CODE = chart
                   AND STATUS = 'A'
                   AND LEVEL5_FUND IS NULL
                   AND LEVEL1_FUND = (SELECT TT_GRANT.YWKFINC.F_GET_FUND_HIER (
                                                '',
                                                chart,
                                                fund,
                                                SYSDATE,
                                                1,
                                                'CODE')
                                        FROM DUAL)
                   AND ERRTYPE = 'E'
                   AND ROWNUM = 1;
         ELSE
            SELECT ERRTYPE
              INTO BAVLERROR
              FROM TT_HR_PASS.NC_PASS_BAVLERR_C
             WHERE     COAS_CODE = chart
                   AND STATUS = 'A'
                   AND LEVEL5_FUND IS NULL
                   AND LEVEL1_FUND = (SELECT TT_GRANT.YWKFINC.F_GET_FUND_HIER (
                                                '',
                                                chart,
                                                fund,
                                                SYSDATE,
                                                1,
                                                'CODE')
                                        FROM DUAL)
                   AND ERRTYPE = 'W'
                   AND ROWNUM = 1;
         END IF;
      ELSE
         SELECT COUNT (*)
           INTO BAVLERRORFUNDTYPE
           FROM TT_HR_PASS.NC_PASS_BAVLERR_C
          WHERE     COAS_CODE = chart
                AND ERRTYPE = 'E'
                AND STATUS = 'A'
                AND LEVEL1_FUND IS NULL
                AND LEVEL5_FUND IS NULL
                AND FUND_TYPE =
                       (SELECT DISTINCT FTVFUND_FTYP_CODE
  			FROM FTVFUND T1
 			WHERE     T1.FTVFUND_COAS_CODE = chart
       			AND T1.FTVFUND_FUND_CODE = fund
       			AND T1.FTVFUND_EFF_DATE =
              			(SELECT MAX (T11.FTVFUND_EFF_DATE)
                 			FROM FTVFUND T11
                			WHERE     T1.FTVFUND_FUND_CODE = T11.FTVFUND_FUND_CODE
                      			AND T1.FTVFUND_COAS_CODE = T11.FTVFUND_COAS_CODE
                      			AND T11.FTVFUND_EFF_DATE <= SYSDATE));


         IF (BAVLERRORFUNDTYPE > 0)
         THEN
            SELECT ERRTYPE
              INTO BAVLERROR
              FROM TT_HR_PASS.NC_PASS_BAVLERR_C
             WHERE     COAS_CODE = chart
                   AND STATUS = 'A'
                   AND ERRTYPE = 'E'
                   AND ROWNUM = 1
                   AND LEVEL1_FUND IS NULL
                   AND LEVEL5_FUND IS NULL
                   AND FUND_TYPE =
                          (SELECT DISTINCT FTVFUND_FTYP_CODE
  			     FROM FTVFUND T1
 			    WHERE     T1.FTVFUND_COAS_CODE = chart
       			      AND T1.FTVFUND_FUND_CODE = fund
       			      AND T1.FTVFUND_EFF_DATE =
              			(SELECT MAX (T11.FTVFUND_EFF_DATE)
                 			FROM FTVFUND T11
                			WHERE     T1.FTVFUND_FUND_CODE = T11.FTVFUND_FUND_CODE
                      			AND T1.FTVFUND_COAS_CODE = T11.FTVFUND_COAS_CODE
                      			AND T11.FTVFUND_EFF_DATE <= SYSDATE));
         ELSE
            SELECT ERRTYPE
              INTO BAVLERROR
              FROM TT_HR_PASS.NC_PASS_BAVLERR_C
             WHERE     COAS_CODE = chart
                   AND STATUS = 'A'
                   AND ERRTYPE = 'W'
                   AND ROWNUM = 1
                   AND LEVEL1_FUND IS NULL
                   AND LEVEL5_FUND IS NULL
                   AND FUND_TYPE =
                          (SELECT DISTINCT FTVFUND_FTYP_CODE
  			     FROM FTVFUND T1
 			    WHERE     T1.FTVFUND_COAS_CODE = chart
       			     AND T1.FTVFUND_FUND_CODE = fund
       			     AND T1.FTVFUND_EFF_DATE =
              			(SELECT MAX (T11.FTVFUND_EFF_DATE)
                 			FROM FTVFUND T11
                			WHERE     T1.FTVFUND_FUND_CODE = T11.FTVFUND_FUND_CODE
                      			AND T1.FTVFUND_COAS_CODE = T11.FTVFUND_COAS_CODE
                      			AND T11.FTVFUND_EFF_DATE <= SYSDATE));
         END IF;
      END IF;
   END IF;

return bavlError;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return bavlError;
     WHEN OTHERS THEN
       RAISE;

END f_check_bavl_ctrl_table;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_pooled_position
-- PRODUCT....: HR
-- USAGE......: check pooled position for chart, pclass, orgn and fiscal year.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return posn code to check pooled position for chart, pclass, orgn and fiscal year.
--------------------------------------------------------------------------------------------

function f_check_pooled_position(
     chart  varchar2,
     pcls  varchar2,
     orgn  varchar2,
     fisc_code varchar2)
     return varchar2
  as
     pooledposn varchar2(9) default null;
     pooled_status varchar2(9) default null;

BEGIN        
        
SELECT status
  INTO pooled_status
  FROM tt_hr_pass.nc_pass_psexception_c
 WHERE     coas_code = chart
       AND pcls_code = pcls
       and status = 'A' and rownum = 1;

IF(pooled_status = 'A') THEN

 SELECT DISTINCT nbrptot_posn
  INTO pooledposn
  FROM nbrptot
 WHERE     nbrptot_coas_code = chart
       AND nbrptot_orgn_code = orgn
       AND nbrptot_posn IN (SELECT nbbposn_posn
                              FROM nbbposn
                             WHERE     nbbposn_pcls_code = pcls
                                   AND nbbposn_coas_code = chart
                                   AND nbbposn_status = 'A')
       AND ROWNUM = 1;
        
END IF;  

return pooledposn;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       RETURN pooledposn;
     WHEN OTHERS THEN
       RAISE;

END f_check_pooled_position;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_position_number
-- PRODUCT....: HR
-- USAGE......: get_position_number for trans number.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return posn number for transaction number.
--------------------------------------------------------------------------------------------

FUNCTION F_GET_POSN_NUMBER (TRANS_NUMBER VARCHAR2)
   RETURN VARCHAR2
AS
   POSN_NUMBER VARCHAR2(9);
BEGIN

   SELECT NVL(POSN_NBR,0)
    INTO POSN_NUMBER
     FROM TT_HR_PASS.NC_PASS_TRANS_B
    WHERE TRANS_NO = TRANS_NUMBER;

   RETURN POSN_NUMBER;
   
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       RETURN POSN_NUMBER;
     WHEN OTHERS THEN
       RAISE;   
END F_GET_POSN_NUMBER;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_PayRangeList
-- PRODUCT....: HR
-- USAGE......: get pay range list for trans number.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return pay range for transaction number.
--------------------------------------------------------------------------------------------

FUNCTION f_get_PayRangeList (transNo varchar2)
   RETURN SYS_REFCURSOR
AS
   c_payrange  SYS_REFCURSOR;
   effe_date DATE;
   fy_code VARCHAR2(4);
   v_code   NUMBER;
   v_errm   VARCHAR2 (64);

BEGIN

IF transNo is not null THEN

select SUBSTR (POSN_EFFECTIVE_DATE, 0) 
into effe_date
FROM TT_HR_PASS.NC_PASS_TRANS_B WHERE TRANS_NO = transNo;    

select TTUFISCAL.PWKMISC.f_get_fiscalyear(effe_date)
into fy_code 
from dual;                             

OPEN c_payrange FOR

SELECT ROUND(NTRSALB_LOW, 2) AS LOW, ROUND(NTRSALB_MIDPOINT, 2) AS MID, ROUND(NTRSALB_HIGH, 2) AS HIGH
  FROM NTRSALB
 WHERE     NTRSALB_GRADE IN (SELECT POSN_PAY_GRADE AS PAYGRADE
                               FROM TT_HR_PASS.NC_PASS_TRANS_B
                              WHERE TRANS_NO = transNo)
       AND NTRSALB_SGRP_CODE IN (SELECT 'FY' || SUBSTR (fy_code, 3, 2)
                                           AS FYYEAR
                                   FROM DUAL);

END IF;

RETURN c_payrange;

EXCEPTION
      WHEN OTHERS
      THEN         
         v_code := SQLCODE;
         v_errm := SUBSTR (SQLERRM, 1, 64);
         DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);    

END  f_get_PayRangeList;  
   
--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_dept_org_by_chart
-- PRODUCT....: HR
-- USAGE......: get department org list for chart.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return Department ORGN and Title
--------------------------------------------------------------------------------------------

FUNCTION f_get_dept_org_by_chart (chart varchar2)
   RETURN SYS_REFCURSOR
AS
   c_orgnlist  SYS_REFCURSOR;
BEGIN
IF chart in ('T','S') THEN
OPEN c_orgnlist for
    SELECT ORGANIZATION_CODE, ORGANIZATION_DESC, CHART_OF_ACCOUNTS
                  FROM TTUFISCAL.FWVORGN
                 WHERE ORGANIZATION_LEVEL = '07'
                   AND CHART_OF_ACCOUNTS = chart
                   AND ORGANIZATION_STATUS = 'A';
   ELSE 
   OPEN c_orgnlist for
 SELECT ORGANIZATION_CODE, ORGANIZATION_DESC, CHART_OF_ACCOUNTS
                  FROM TTUFISCAL.FWVORGN
                 WHERE ORGANIZATION_LEVEL = '05'
                   AND CHART_OF_ACCOUNTS = chart
                   AND ORGANIZATION_STATUS = 'A';  
   END IF; 
RETURN c_orgnlist;
END  f_get_dept_org_by_chart;  

   
--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_findPositionByDept
-- PRODUCT....: HR
-- USAGE......: get position list with salary for a given ORGN.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return position list with salary for a given ORGN
--------------------------------------------------------------------------------------------

FUNCTION f_findPositionByDept (chart varchar2, orgCode varchar2, attrCode varchar2)
   RETURN SYS_REFCURSOR
AS
   c_orgn7list  SYS_REFCURSOR;
BEGIN
IF chart in ('T', 'S') THEN
OPEN c_orgn7list for
     select N.NBRPTOT_POSN as posn, N.NBRPTOT_BUDGET as annual_salary,P.NBBPOSN_TITLE as job_title, P.NBBPOSN_PCLS_CODE as pcls_code, N.NBRPTOT_FISC_CODE as fisc_code, N.NBRPTOT_STATUS as status, NULL as campus
     from nbrptot n,nbbposn p
      where
      N.nbrptot_coas_code=chart
      and N.nbrptot_orgn_code =orgCode and
      N.NBRPTOT_POSN = P.NBBPOSN_POSN  and
      P.NBBPOSN_STATUS in ('A','F') and
      N.nbrptot_effective_date = (SELECT MAX (t1.nbrptot_effective_date)
                         FROM nbrptot t1
                        WHERE     N.nbrptot_posn = t1.nbrptot_posn
                              AND N.nbrptot_status in ('A','W'))
                              AND
      (P.NBBPOSN_ECLS_CODE LIKE 'E%' OR P.NBBPOSN_ECLS_CODE LIKE 'N%' OR  P.NBBPOSN_ECLS_CODE LIKE 'F%'); 
 ELSE
 OPEN c_orgn7list for
 SELECT * from (
SELECT * from (
select N.NBRPTOT_POSN as posn,N.NBRPTOT_ORGN_CODE as orgn,N.NBRPTOT_BUDGET as annual_salary,P.NBBPOSN_TITLE as job_title, P.NBBPOSN_PCLS_CODE as pcls_code, N.NBRPTOT_FISC_CODE as fisc_code, N.NBRPTOT_STATUS as status
     from nbrptot n,nbbposn p
     where
      N.nbrptot_coas_code= chart
      and N.nbrptot_orgn_code in( select ORGANIZATION_CODE from ttufiscal.fwvorgn where ORGANIZATION_LEVEL_5= orgCode and CHART_OF_ACCOUNTS = chart and ORGANIZATION_LEVEL = '07' and ORGANIZATION_STATUS = 'A')   
      and N.NBRPTOT_POSN = P.NBBPOSN_POSN and
      P.NBBPOSN_STATUS in ('A','F') and
      N.nbrptot_effective_date = (SELECT MAX (t1.nbrptot_effective_date)
                         FROM nbrptot t1
                        WHERE     N.nbrptot_posn = t1.nbrptot_posn
                              AND N.nbrptot_status in ('A','W'))
                              AND
      (P.NBBPOSN_ECLS_CODE LIKE 'E%' OR P.NBBPOSN_ECLS_CODE LIKE 'N%' OR  P.NBBPOSN_ECLS_CODE LIKE 'F%')
      ) q1
      JOIN
      (select ORGANIZATION_CODE as orgn7, ORGANIZATION_LEVEL_5 as orgn5 from ttufiscal.fwvorgn where ORGANIZATION_LEVEL_5=orgCode and CHART_OF_ACCOUNTS = chart and ORGANIZATION_LEVEL = '07' and ORGANIZATION_STATUS = 'A') q2
      on q1.orgn = q2.orgn7) ot1
      JOIN
      (SELECT  T1.FTRORGA_ORGN_CODE, T2.FTRATTV_CODE, T2.FTRATTV_DESC as campus
  FROM   FTRORGA T1,FTRATTV T2
  WHERE  T1.FTRORGA_COAS_CODE    = chart
  AND    T1.FTRORGA_ATTT_CODE    = attrCode
  AND    T2.FTRATTV_ATTT_CODE    = T1.FTRORGA_ATTT_CODE
  AND    T1.FTRORGA_ORGN_CODE    = orgCode
  AND    T1.FTRORGA_ATTV_CODE    = T2.FTRATTV_CODE) ot2
  on ot1.orgn5 = ot2.FTRORGA_ORGN_CODE;
END IF;             
RETURN c_orgn7list;
END  f_findPositionByDept;  


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_Position_class_list
-- PRODUCT....: HR
-- USAGE......: get position class list.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return position class for fiscal year.
--------------------------------------------------------------------------------------------

FUNCTION F_GET_POSITION_CLASS_LIST
   RETURN SYS_REFCURSOR
AS
   C_POSN_CLS SYS_REFCURSOR;
BEGIN
   OPEN C_POSN_CLS FOR
      
     SELECT NTRPCLS_CODE as code,
               NTRPCLS_DESC as description,
               NTRPCLS_ECLS_CODE as eclscode,
               NTRPCLS_GRADE as paygrade
          FROM NTRPCLS T1
         WHERE NTRPCLS_SGRP_CODE =
                  (SELECT MAX (NTRPCLS_SGRP_CODE)
                     FROM NTRPCLS T11
                    WHERE     T11.NTRPCLS_CODE = T1.NTRPCLS_CODE
                          AND T11.NTRPCLS_SGRP_CODE = T1.NTRPCLS_SGRP_CODE
                          AND UPPER (T11.NTRPCLS_DESC) NOT LIKE '%DO N%'
                          AND UPPER (T11.NTRPCLS_DESC) NOT LIKE '%DNU%'
                          AND UPPER (T11.NTRPCLS_DESC) NOT LIKE '%DONOT%'
                          AND UPPER (T11.NTRPCLS_DESC) NOT LIKE '%DON''%');	

   RETURN C_POSN_CLS;
END F_GET_POSITION_CLASS_LIST;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_supervisor
-- PRODUCT....: HR
-- USAGE......: get supervisor ORACLE ID for a given transaction.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return supervisor oracle id for a transaction
--------------------------------------------------------------------------------------------

FUNCTION f_get_supervisor (transNo varchar2)
   RETURN SYS_REFCURSOR
AS
   c_superlist  SYS_REFCURSOR;
BEGIN
   OPEN c_superlist for
  SELECT f.FWVATUE_ORACLE_ID AS ORACLE_ID
    FROM TTUFISCAL.FWVATUE f
    INNER JOIN TT_HR_PASS.NC_PASS_TRANS_B tr
    ON tr.TRANS_ID =  transNo
    AND f.FWVATUE_PIDM = tr.POSN_SUPERVISOR_PIDM;
RETURN c_superlist;
END  f_get_supervisor; 


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_deptHead
-- PRODUCT....: HR
-- USAGE......: To get department head for given L7orgn code.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return department head for a orgn
--------------------------------------------------------------------------------------------

FUNCTION f_get_deptHead (chart varchar2 , orgCode varchar2)
   RETURN SYS_REFCURSOR
AS
   c_deptHead  SYS_REFCURSOR;
BEGIN
      open c_deptHead for
      SELECT FTVORGN_FMGR_CODE_PIDM
      FROM FIMSMGR.FTVORGN
      WHERE FTVORGN_ORGN_CODE = (SELECT TT_HR_PASS.NWKPASS.f_get_orgnCodeHierarchyByLevel(chart, orgCode, sysdate, '5') FROM DUAL)--level5 campus
      AND FTVORGN_STATUS_IND = 'A'
      AND FTVORGN_COAS_CODE = chart
      AND FTVORGN_EFF_DATE <= sysdate
      AND (FTVORGN_TERM_DATE IS NULL OR FTVORGN_TERM_DATE >= sysdate)
      AND TRUNC(FTVORGN_NCHG_DATE) >= sysdate;
    RETURN c_deptHead;
END  f_get_deptHead; 

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_orgnCodeHierarchyByLevel
-- PRODUCT....: HR
-- USAGE......: To get Org level by hierarchy.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return level orgn by hierarchy
--------------------------------------------------------------------------------------------

FUNCTION f_get_orgnCodeHierarchyByLevel (chartCode VARCHAR2, orgnCode VARCHAR2, effectiveDate DATE, levelNumber NUMERIC)
RETURN VARCHAR2
AS
   FTVORGN_ORGN_CODE VARCHAR2(9);
BEGIN

  SELECT FTVORGN_ORGN_CODE INTO FTVORGN_ORGN_CODE
               FROM (SELECT t.*,
               row_number() over (order by num desc) as hierarchy
               from (SELECT c.*, rownum as num
                       FROM FTVORGN c
                      WHERE c.FTVORGN_COAS_CODE = chartCode
                      START WITH c.FTVORGN_ORGN_CODE = orgnCode
                            AND c.FTVORGN_EFF_DATE <= effectiveDate
                            AND c.FTVORGN_NCHG_DATE > effectiveDate
                     CONNECT BY PRIOR c.FTVORGN_COAS_CODE = c.FTVORGN_COAS_CODE
                            AND PRIOR c.FTVORGN_ORGN_CODE_PRED = c.FTVORGN_ORGN_CODE
                            AND c.FTVORGN_EFF_DATE <= effectiveDate
                            AND c.FTVORGN_NCHG_DATE > effectiveDate) t) o
              WHERE hierarchy = levelNumber;
   RETURN FTVORGN_ORGN_CODE;
END f_get_orgnCodeHierarchyByLevel;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_regionalDean
-- PRODUCT....: HR
-- USAGE......: To get regional Dean for given L7orgn code.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return regional dean for a orgn
--------------------------------------------------------------------------------------------

FUNCTION f_get_regionalDean (chart varchar2 , orgCode varchar2)
   RETURN SYS_REFCURSOR
AS
   c_regDean  SYS_REFCURSOR;
BEGIN
      open c_regDean for
      SELECT FTVORGN_FMGR_CODE_PIDM
      FROM FIMSMGR.FTVORGN
      WHERE FTVORGN_ORGN_CODE = (SELECT TT_HR_PASS.NWKPASS.f_get_orgnCodeHierarchyByLevel(chart, orgCode, sysdate, '3') FROM DUAL)--level3 campus
      AND FTVORGN_STATUS_IND = 'A'
      AND FTVORGN_COAS_CODE = chart
      AND FTVORGN_EFF_DATE <= sysdate
      AND (FTVORGN_TERM_DATE IS NULL OR FTVORGN_TERM_DATE >= sysdate)
      AND TRUNC(FTVORGN_NCHG_DATE) >= sysdate;
    RETURN c_regDean;
END  f_get_regionalDean; 

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_deanOrVP
-- PRODUCT....: HR
-- USAGE......: To get Dean/VP for given L7orgn code.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return dean or VP for a orgn
--------------------------------------------------------------------------------------------

FUNCTION f_get_deanOrVP (chart varchar2 , orgCode varchar2)
   RETURN SYS_REFCURSOR
AS
   c_deanOrVP  SYS_REFCURSOR;
BEGIN
      open c_deanOrVP for
      SELECT FTVORGN_FMGR_CODE_PIDM
      FROM FIMSMGR.FTVORGN
      WHERE FTVORGN_ORGN_CODE = (SELECT TT_HR_PASS.NWKPASS.f_get_orgnCodeHierarchyByLevel(chart, orgCode, sysdate, '2') FROM DUAL)--level2 campus
      AND FTVORGN_STATUS_IND = 'A'
      AND FTVORGN_COAS_CODE = chart
      AND FTVORGN_EFF_DATE <= sysdate
      AND (FTVORGN_TERM_DATE IS NULL OR FTVORGN_TERM_DATE >= sysdate)
      AND TRUNC(FTVORGN_NCHG_DATE) >= sysdate;
    RETURN c_deanOrVP;
END  f_get_deanOrVP; 



--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_salary_approved_posn
-- PRODUCT....: HR
-- USAGE......: get_position_number for trans number.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will return total salary for the position.
--------------------------------------------------------------------------------------------

FUNCTION f_get_salary_approved_posn (posn varchar2,fisc_code  varchar2)
   RETURN NUMBER
AS
   salary NUMBER;
BEGIN
  select sum(NBRPTOT_BUDGET) into salary
  from nbrptot 
  where nbrptot_posn = posn 
  and nbrptot_status in ('A','T') 
  and nbrptot_fisc_code = fisc_code
  group by nbrptot_posn;
  RETURN salary;
END f_get_salary_approved_posn;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_posn_number
-- PRODUCT....: HR/Reclassification
-- USAGE......: get position numbers list.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return active and frozen position numbers for chart.
--------------------------------------------------------------------------------------------

FUNCTION f_get_positions_numbers (coas_code VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_posn_num   SYS_REFCURSOR;

BEGIN

IF coas_code = 'H' THEN
OPEN c_posn_num FOR
      SELECT DISTINCT NBBPOSN_posn
        FROM NBBPOSN
       WHERE NBBPOSN_coas_code = coas_code AND NBBPOSN_status IN ('A', 'F');
       
ELSIF coas_code = 'E' THEN
OPEN c_posn_num FOR
      SELECT DISTINCT NBBPOSN_posn
        FROM NBBPOSN
       WHERE NBBPOSN_coas_code = coas_code AND NBBPOSN_TYPE IN ('S') AND NBBPOSN_status IN ('A', 'F');
       
ELSE
OPEN c_posn_num FOR
      SELECT DISTINCT NBBPOSN_posn
        FROM NBBPOSN
       WHERE NBBPOSN_coas_code IN ('T','S') AND NBBPOSN_TYPE IN ('S') AND NBBPOSN_status IN ('A');

END IF;  

RETURN c_posn_num;
END f_get_positions_numbers;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_is_vacant_posn
-- PRODUCT....: HR
-- USAGE......: finds if the position is vacant based on posn number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return Y or N if the position is vacant based on posn number
--------------------------------------------------------------------------------------------

function f_is_vacant_posn(posn_number VARCHAR2)
     return VARCHAR2
  as
     VACANT_ROWS varchar2(2);
     IS_VACANT varchar2(2) := 'N';

BEGIN

SELECT COUNT (DISTINCT NBBPOSN_POSN)
  INTO VACANT_ROWS
  FROM NBBPOSN, NBRPTOT
 WHERE     NBBPOSN_STATUS IN ('A', 'F')
       AND NBBPOSN_COAS_CODE = substr(posn_number,0,1)
       AND NBRPTOT_STATUS = 'A'
       AND NBBPOSN_POSN = NBRPTOT_POSN
       AND NBBPOSN_POSN = posn_number
       AND NOT EXISTS
                  (SELECT *
                     FROM NBRBJOB
                    WHERE     NBRBJOB_POSN = NBBPOSN_POSN
                          AND (   ( NBRBJOB_END_DATE IS NULL
                                   AND NBRBJOB_BEGIN_DATE < SYSDATE)
                               OR NBRBJOB_END_DATE > SYSDATE));
                               
IF VACANT_ROWS = 1 THEN
 IS_VACANT := 'Y';
ELSE
 IS_VACANT := 'N';             
END IF;

return IS_VACANT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return IS_VACANT;
     WHEN OTHERS THEN
       RAISE;

END f_is_vacant_posn;



---------------------------------------------------------------------------------------------

-- OBJECT NAME: f_get_budget_vacant_posns
-- PRODUCT....: HR
-- USAGE......: gets the budget for vacant positions
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return the budget for vacant positions
--------------------------------------------------------------------------------------------

FUNCTION f_get_budget_vacant_posns (posn_number    VARCHAR2,
                                    fisc_year      VARCHAR2)
   RETURN NUMBER
AS
   COUNT_BUDGET    NUMBER;
   VACANT_BUDGET   NUMBER:= 0;
   v_code          NUMBER;
   v_errm          VARCHAR2 (64);
   
BEGIN
   IF fisc_year > TO_CHAR (SYSDATE, 'YYYY')
   THEN
        SELECT COUNT (*)
          INTO COUNT_BUDGET
          FROM NBRPTOT T1
         WHERE     NBRPTOT_POSN = POSN_NUMBER
               AND NBRPTOT_STATUS IN ('W')
               AND NBRPTOT_FISC_CODE = fisc_year;

      IF COUNT_BUDGET > 0
      THEN
           SELECT NVL (SUM (NBRPTOT_BUDGET), 0)
             INTO VACANT_BUDGET
             FROM NBRPTOT T1
            WHERE     NBRPTOT_POSN = POSN_NUMBER
                  AND NBRPTOT_STATUS IN ('W')
                  AND NBRPTOT_FISC_CODE = fisc_year
         GROUP BY NBRPTOT_POSN;
      ELSE
           SELECT NVL (SUM (NBRPTOT_BUDGET), 0)
             INTO VACANT_BUDGET
             FROM NBRPTOT T1
            WHERE NBRPTOT_POSN = POSN_NUMBER AND NBRPTOT_STATUS IN ('A', 'T')
         GROUP BY NBRPTOT_POSN;
      END IF;
      
   ELSE
        SELECT NVL (SUM (NBRPTOT_BUDGET), 0)
          INTO VACANT_BUDGET
          FROM NBRPTOT T1
         WHERE     NBRPTOT_POSN = POSN_NUMBER
               AND NBRPTOT_STATUS IN ('A', 'T')
               AND NBRPTOT_FISC_CODE = fisc_year
      GROUP BY NBRPTOT_POSN;
   END IF;

   RETURN VACANT_BUDGET;
   
EXCEPTION
   WHEN OTHERS
   THEN
      VACANT_BUDGET := 0;
      v_code := SQLCODE;
      v_errm := SUBSTR (SQLERRM, 1, 64);
      DBMS_OUTPUT.PUT_LINE ('The error code is ' || v_code || '- ' || v_errm);     


END f_get_budget_vacant_posns;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_is_empty_sup_secondary_posn
-- PRODUCT....: HR
-- USAGE......: finds if the secondary position has empty supervisor information in Nbrjobs
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return Y or N if the position is secondary position has empty supervisor information in Nbrjobs
--------------------------------------------------------------------------------------------

function f_is_empty_sup_secondary_posn(posn_number VARCHAR2, pidm VARCHAR2)
     return VARCHAR2
  as
     VACANT_ROWS varchar2(2);
     IS_EMPTY_SEC varchar2(2) := 'N';

BEGIN

SELECT COUNT(*)
INTO VACANT_ROWS
FROM NBRJOBS T1, NBRBJOB WHERE 
T1.NBRJOBS_STATUS = 'A'
AND T1.NBRJOBS_SUFF = NBRBJOB_SUFF
AND NBRBJOB_CONTRACT_TYPE <> 'O'
AND T1.NBRJOBS_SUPERVISOR_PIDM IS NULL
AND T1.NBRJOBS_PIDM = NBRBJOB_PIDM
AND T1.NBRJOBS_POSN = posn_number
AND T1.NBRJOBS_PIDM = pidm
AND NBRBJOB_POSN = T1.NBRJOBS_POSN 
--AND NBRBJOB_CONTRACT_TYPE IN ('S')
AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE >= SYSDATE))
AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE);

IF VACANT_ROWS >= 1 THEN
 IS_EMPTY_SEC := 'Y';
ELSE
 IS_EMPTY_SEC := 'N';
END IF;

return IS_EMPTY_SEC;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return IS_EMPTY_SEC;
     WHEN OTHERS THEN
       RAISE;

END f_is_empty_sup_secondary_posn;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_is_primary_posn
-- PRODUCT....: HR
-- USAGE......: finds if the position has a primary posn or is a primary posn and not empty supervisor
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return Y or N if the position has a primary posn or is a primary posn
--------------------------------------------------------------------------------------------

function f_is_primary_posn(posn_number VARCHAR2, pidm VARCHAR2)
     return VARCHAR2
  as
     POSN_ROWS varchar2(2);
     IS_PRIM varchar2(2) := 'N';

BEGIN

SELECT COUNT(*)
INTO POSN_ROWS
FROM NBRJOBS T1, NBRBJOB 
WHERE T1.NBRJOBS_STATUS = 'A'
AND T1.NBRJOBS_SUFF = NBRBJOB_SUFF
AND T1.NBRJOBS_POSN = posn_number
AND T1.NBRJOBS_PIDM = pidm
AND NBRBJOB_PIDM = T1.NBRJOBS_PIDM
AND NBRBJOB_POSN = T1.NBRJOBS_POSN
AND T1.NBRJOBS_SUPERVISOR_PIDM IS NOT NULL
AND NBRBJOB_CONTRACT_TYPE IN ('P')
AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE >= SYSDATE))
AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE); 

IF POSN_ROWS >= 1 THEN
 IS_PRIM := 'Y';
ELSE
 IS_PRIM := 'N';
END IF;

return IS_PRIM;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return IS_PRIM;
     WHEN OTHERS THEN
       RAISE;

END f_is_primary_posn;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_employee_info
-- PRODUCT....: HR/Reclassification
-- USAGE......: get employee info based on position number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return employee info based on position number.
--------------------------------------------------------------------------------------------

FUNCTION f_get_employee_info (posn_number VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_emp_list   SYS_REFCURSOR;

BEGIN 

IF(f_is_vacant_posn(posn_number) = 'Y') THEN

OPEN c_emp_list FOR 

select * from dual where 1=0; 

ELSE

OPEN c_emp_list FOR 

SELECT SPRIDEN_LAST_NAME,
       SPRIDEN_MI,
       SPRIDEN_FIRST_NAME,
       SPRIDEN_ID
  FROM SPRIDEN
 WHERE     SPRIDEN_CHANGE_IND IS NULL
       AND SPRIDEN_PIDM IN (SELECT DISTINCT NBRJOBS_PIDM
                              FROM NBRJOBS T1
                             WHERE     T1.NBRJOBS_POSN = posn_number
                                   AND T1.NBRJOBS_STATUS = 'A'
                                   AND T1.NBRJOBS_EFFECTIVE_DATE =
                                          (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                                             FROM NBRJOBS T11
                                            WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                                  AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                                  AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                                                  AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE));

END IF;

   RETURN c_emp_list;

END f_get_employee_info;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_current_position_info
-- PRODUCT....: HR/Reclassification
-- USAGE......: get current position info based on position number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return current position info based on position number.
--------------------------------------------------------------------------------------------

FUNCTION f_get_current_position_info (posn_number VARCHAR2, empId VARCHAR2, fisc_year varchar2)
   RETURN SYS_REFCURSOR
AS
   c_posn_list   SYS_REFCURSOR;   
   pidm number(8);
   VACANT_BUDGET number(10,2):= 0;
   v_code   NUMBER;
   v_errm   VARCHAR2 (64);
   
   
BEGIN

IF(f_is_vacant_posn(posn_number) = 'Y') THEN

   VACANT_BUDGET := f_get_budget_vacant_posns(posn_number, fisc_year);
   
   IF (SUBSTR(posn_number, 0, 1) = 'T' OR SUBSTR(posn_number, 0, 1) = 'S') THEN

   OPEN c_posn_list FOR

   SELECT NBBPOSN_PCLS_CODE AS PCLS_CODE,
       NBBPOSN_TITLE AS PCLS_TITLE,
       NBBPOSN_ECLS_CODE AS ECLS_CODE,
       NBBPOSN_TYPE AS POSN_TYPE,
       PTRECLS_PICT_CODE AS PICT_CODE,
       T1.NBRPTOT_COAS_CODE AS COAS_CODE,
       T1.NBRPTOT_ORGN_CODE AS ORGN_CODE,
       PWVORGN_ORGN_TITLE AS ORGN_TITLE,
       T1.NBRPTOT_FTE AS POSN_FTE,
       NBBPOSN_GRADE AS POSN_GRADE,
       VACANT_BUDGET AS POSN_ANNUAL_AMT
   FROM NBRPTOT T1,
       NBBPOSN,
       PTRECLS,
       TTUFISCAL.PWVORGN
   WHERE     NBRPTOT_POSN = posn_number
       AND NBBPOSN_POSN = NBRPTOT_POSN
       AND PWVORGN_COAS_CODE = T1.NBRPTOT_COAS_CODE
       AND PWVORGN_ORGN_CODE = T1.NBRPTOT_ORGN_CODE
       AND Ptrecls_code = NBBPOSN_ECLS_CODE
       AND NBRPTOT_EFFECTIVE_DATE =
              (SELECT MAX (NBRPTOT_EFFECTIVE_DATE)
                 FROM NBRPTOT T11
                WHERE T11.NBRPTOT_POSN = T1.NBRPTOT_POSN);
          
    ELSE	

    OPEN c_posn_list FOR

    SELECT NBBPOSN_PCLS_CODE AS PCLS_CODE,
       NBBPOSN_TITLE AS PCLS_TITLE,
       NBBPOSN_ECLS_CODE AS ECLS_CODE,
       NBBPOSN_TYPE AS POSN_TYPE,
       PTRECLS_PICT_CODE AS PICT_CODE,
       T1.NBRPTOT_COAS_CODE AS COAS_CODE,
       T1.NBRPTOT_ORGN_CODE AS ORGN_CODE,
       PWVORGN_ORGN_TITLE AS ORGN_TITLE,
       T1.NBRPTOT_FTE AS POSN_FTE,
       NBBPOSN_GRADE AS POSN_GRADE,
       VACANT_BUDGET AS POSN_ANNUAL_AMT
    FROM NBRPTOT T1,
       NBBPOSN,
       PTRECLS,
       TTUFISCAL.PWVORGN
    WHERE     NBRPTOT_POSN = posn_number
       AND NBBPOSN_POSN = NBRPTOT_POSN
       AND PWVORGN_COAS_CODE = T1.NBRPTOT_COAS_CODE
       AND PWVORGN_ORGN_CODE = T1.NBRPTOT_ORGN_CODE
       AND Ptrecls_code = NBBPOSN_ECLS_CODE
       AND NBRPTOT_EFFECTIVE_DATE =
              (SELECT MAX (NBRPTOT_EFFECTIVE_DATE)
                 FROM NBRPTOT T11
                WHERE T11.NBRPTOT_POSN = T1.NBRPTOT_POSN
          AND T11.NBRPTOT_EFFECTIVE_DATE <= SYSDATE);
          
    END IF;          


ELSE


BEGIN
   SELECT SPRIDEN_PIDM
     INTO pidm
     FROM SPRIDEN
    WHERE SPRIDEN_ID = empId AND SPRIDEN_CHANGE_IND IS NULL;
EXCEPTION
   WHEN OTHERS
   THEN
      pidm := 0;
      v_code := SQLCODE;
      v_errm := SUBSTR (SQLERRM, 1, 64);
      DBMS_OUTPUT.PUT_LINE ('The error code is ' || v_code || '- ' || v_errm);
END;
 
 
IF(f_is_primary_posn(posn_number, pidm) = 'Y') THEN

    OPEN c_posn_list FOR

    SELECT SPRIDEN_LAST_NAME,
       SPRIDEN_MI,
       SPRIDEN_FIRST_NAME,
       SPRIDEN_ID,
       NBBPOSN_PCLS_CODE,
       NBBPOSN_TITLE,
       NBBPOSN_ECLS_CODE,
       NBBPOSN_TYPE,
       NBRBJOB_CONTRACT_TYPE,
       T1.NBRJOBS_PIDM,
       T1.NBRJOBS_SUFF,
       T1.NBRJOBS_PICT_CODE,
       P1.NBRPTOT_COAS_CODE AS COAS_CODE,
       P1.NBRPTOT_ORGN_CODE AS ORGN_CODE,
       PWVORGN_ORGN_TITLE,
       T1.NBRJOBS_SUPERVISOR_PIDM,
       T1.NBRJOBS_FTE,
       T1.NBRJOBS_SAL_GRADE,
       T1.NBRJOBS_ANN_SALARY,
       T1.NBRJOBS_JCRE_CODE
  FROM SPRIDEN,
       NBBPOSN,
       NBRBJOB,
       NBRJOBS T1,
       NBRPTOT P1,
       TTUFISCAL.PWVORGN
 WHERE     NBBPOSN_POSN = posn_number
       AND NBRBJOB_POSN = NBBPOSN_POSN
     --AND ((NBRBJOB_END_DATE IS NULL AND NBRBJOB_BEGIN_DATE < SYSDATE) OR NBRBJOB_END_DATE > SYSDATE)
       AND NBRBJOB_CONTRACT_TYPE IN ('P')
       AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
       AND NBRBJOB_PIDM = T1.NBRJOBS_PIDM
       AND T1.NBRJOBS_PIDM =  pidm
       AND T1.NBRJOBS_POSN = NBBPOSN_POSN
       AND T1.NBRJOBS_POSN = NBRBJOB_POSN
       AND T1.NBRJOBS_STATUS = 'A'
       AND T1.NBRJOBS_SUFF = NBRBJOB_SUFF
       AND NBRBJOB_CONTRACT_TYPE <> 'O'
       AND NBBPOSN_POSN = P1.NBRPTOT_POSN
       AND PWVORGN_COAS_CODE = P1.NBRPTOT_COAS_CODE
       AND PWVORGN_ORGN_CODE = P1.NBRPTOT_ORGN_CODE
       AND SPRIDEN_PIDM = T1.NBRJOBS_SUPERVISOR_PIDM
       AND SPRIDEN_CHANGE_IND IS NULL
       AND P1.NBRPTOT_EFFECTIVE_DATE =
              (SELECT MAX (P11.NBRPTOT_EFFECTIVE_DATE)
                 FROM NBRPTOT P11
                WHERE     P11.NBRPTOT_POSN = P1.NBRPTOT_POSN
                      AND P11.NBRPTOT_EFFECTIVE_DATE <= SYSDATE)
       AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE);


ELSE

 IF(f_is_empty_sup_secondary_posn(posn_number, pidm) = 'Y') THEN

   OPEN c_posn_list FOR

   SELECT NULL AS SPRIDEN_LAST_NAME,
       NULL AS SPRIDEN_MI,
       NULL AS SPRIDEN_FIRST_NAME,
       NULL AS SPRIDEN_ID,
       NBBPOSN_PCLS_CODE,
       NBBPOSN_TITLE,
       NBBPOSN_ECLS_CODE,
       NBBPOSN_TYPE,
       NBRBJOB_CONTRACT_TYPE,
       T1.NBRJOBS_PIDM,
       T1.NBRJOBS_SUFF,
       T1.NBRJOBS_PICT_CODE,
       P1.NBRPTOT_COAS_CODE AS COAS_CODE,
       P1.NBRPTOT_ORGN_CODE AS ORGN_CODE,
       PWVORGN_ORGN_TITLE,
       T1.NBRJOBS_SUPERVISOR_PIDM,
       T1.NBRJOBS_FTE,
       T1.NBRJOBS_SAL_GRADE,
       T1.NBRJOBS_ANN_SALARY,
       T1.NBRJOBS_JCRE_CODE
  FROM NBBPOSN,
       NBRBJOB,
       NBRJOBS T1,
       NBRPTOT P1,
       TTUFISCAL.PWVORGN
 WHERE     NBBPOSN_POSN = posn_number
       AND NBRBJOB_POSN = NBBPOSN_POSN
     --AND ((NBRBJOB_END_DATE IS NULL AND NBRBJOB_BEGIN_DATE < SYSDATE) OR NBRBJOB_END_DATE > SYSDATE)
     --AND NBRBJOB_CONTRACT_TYPE in ('S')
       AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
       AND NBRBJOB_CONTRACT_TYPE <> 'O'
       AND NBRBJOB_PIDM = T1.NBRJOBS_PIDM
       AND T1.NBRJOBS_PIDM =  pidm
       AND T1.NBRJOBS_POSN = NBBPOSN_POSN
       AND T1.NBRJOBS_POSN = NBRBJOB_POSN
       AND T1.NBRJOBS_STATUS = 'A'
       AND T1.NBRJOBS_SUFF = NBRBJOB_SUFF
       AND T1.NBRJOBS_SUPERVISOR_PIDM IS NULL
       AND NBBPOSN_POSN = P1.NBRPTOT_POSN
       AND PWVORGN_COAS_CODE = P1.NBRPTOT_COAS_CODE
       AND PWVORGN_ORGN_CODE = P1.NBRPTOT_ORGN_CODE
      -- AND SPRIDEN_PIDM = T1.NBRJOBS_SUPERVISOR_PIDM
      -- AND SPRIDEN_CHANGE_IND IS NULL
       AND P1.NBRPTOT_EFFECTIVE_DATE =
              (SELECT MAX (P11.NBRPTOT_EFFECTIVE_DATE)
                 FROM NBRPTOT P11
                WHERE     P11.NBRPTOT_POSN = P1.NBRPTOT_POSN
                      AND P11.NBRPTOT_EFFECTIVE_DATE <= SYSDATE)
       AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE);


 ELSE

   OPEN c_posn_list FOR

    SELECT SPRIDEN_LAST_NAME,
       SPRIDEN_MI,
       SPRIDEN_FIRST_NAME,
       SPRIDEN_ID,
       NBBPOSN_PCLS_CODE,
       NBBPOSN_TITLE,
       NBBPOSN_ECLS_CODE,
       NBBPOSN_TYPE,
       NBRBJOB_CONTRACT_TYPE,
       T1.NBRJOBS_PIDM,
       T1.NBRJOBS_SUFF,
       T1.NBRJOBS_PICT_CODE,
       P1.NBRPTOT_COAS_CODE AS COAS_CODE,
       P1.NBRPTOT_ORGN_CODE AS ORGN_CODE,
       PWVORGN_ORGN_TITLE,
       T1.NBRJOBS_SUPERVISOR_PIDM,
       T1.NBRJOBS_FTE,
       T1.NBRJOBS_SAL_GRADE,
       T1.NBRJOBS_ANN_SALARY,
       T1.NBRJOBS_JCRE_CODE
  FROM SPRIDEN,
       NBBPOSN,
       NBRBJOB,
       NBRJOBS T1,
       NBRPTOT P1,
       TTUFISCAL.PWVORGN
 WHERE     NBBPOSN_POSN = posn_number
       AND NBRBJOB_POSN = NBBPOSN_POSN
     --AND ((NBRBJOB_END_DATE IS NULL AND NBRBJOB_BEGIN_DATE < SYSDATE) OR NBRBJOB_END_DATE > SYSDATE)
       AND NBRBJOB_CONTRACT_TYPE IN ('S')
       AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
       AND NBRBJOB_PIDM = T1.NBRJOBS_PIDM
       AND T1.NBRJOBS_PIDM =  pidm
       AND T1.NBRJOBS_POSN = NBBPOSN_POSN
       AND T1.NBRJOBS_POSN = NBRBJOB_POSN
       AND T1.NBRJOBS_STATUS = 'A'
       AND T1.NBRJOBS_SUFF = NBRBJOB_SUFF
       AND NBRBJOB_CONTRACT_TYPE <> 'O'
       AND NBBPOSN_POSN = P1.NBRPTOT_POSN
       AND PWVORGN_COAS_CODE = P1.NBRPTOT_COAS_CODE
       AND PWVORGN_ORGN_CODE = P1.NBRPTOT_ORGN_CODE
       AND SPRIDEN_PIDM = T1.NBRJOBS_SUPERVISOR_PIDM
       AND SPRIDEN_CHANGE_IND IS NULL
       AND P1.NBRPTOT_EFFECTIVE_DATE =
              (SELECT MAX (P11.NBRPTOT_EFFECTIVE_DATE)
                 FROM NBRPTOT P11
                WHERE     P11.NBRPTOT_POSN = P1.NBRPTOT_POSN
                      AND P11.NBRPTOT_EFFECTIVE_DATE <= SYSDATE)
       AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE);


 END IF;
 
END IF;


END IF;

   RETURN c_posn_list;
END f_get_current_position_info;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_other_position_info
-- PRODUCT....: HR/Reclassification
-- USAGE......: get other positions info based on position number and employee pidm
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return  other positions info based on position numbe and employee pidm
--------------------------------------------------------------------------------------------

FUNCTION f_get_other_position_info (posn_number VARCHAR2, pidm varchar2, suff varchar2, effDate varchar2, fisc_year varchar2)
   RETURN SYS_REFCURSOR
AS
   c_other_posn_list   SYS_REFCURSOR;
   
BEGIN
   OPEN c_other_posn_list FOR     
      
SELECT NBRJOBS_POSN,
       NBRJOBS_SUFF,
       NBRBJOB_CONTRACT_TYPE,
       NBRJOBS_DESC,
       NBRPTOT_COAS_CODE,
       NBRPTOT_ORGN_CODE,
       NBRJOBS_ANN_SALARY,
       NBRJOBS_FTE,
       NBRJOBS_ECLS_CODE
  FROM NBRJOBS T1, NBRBJOB, NBRPTOT
 WHERE     T1.NBRJOBS_PIDM = pidm
       AND (T1.NBRJOBS_POSN <> posn_number OR T1.NBRJOBS_SUFF <> suff)
       AND T1.NBRJOBS_POSN = NBRBJOB_POSN
       AND T1.NBRJOBS_PIDM = NBRBJOB_PIDM
       AND T1.NBRJOBS_SUFF = NBRBJOB_SUFF
       AND T1.NBRJOBS_STATUS = 'A'
       AND T1.NBRJOBS_POSN = NBRPTOT_POSN
       AND NBRPTOT_FISC_CODE = fisc_year
       AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > to_date(effDate,'MM/dd/yyyy')))	
      --AND NBRBJOB_END_DATE IS NULL
       AND T1.NBRJOBS_EFFECTIVE_DATE IN (SELECT MAX(NBRJOBS_EFFECTIVE_DATE)
                                             FROM NBRJOBS t11
                                            WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                                  AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                                  AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF                                                
                                                  AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE);

   RETURN c_other_posn_list;
END f_get_other_position_info;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_funding_info
-- PRODUCT....: HR/Reclassification
-- USAGE......: get funding info based on position number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return funding info based on position number. If the position is vacant,
--funding info is retrieved from NBRPLBD or if the position is filled, the info is retrieved from
--NBRJLBD, NBRJOBS
--------------------------------------------------------------------------------------------

FUNCTION f_get_funding_info (posn_number VARCHAR2, fisc_year varchar2, fisc_year_code varchar2, futureVacant varchar2, EffDate varchar2, suff varchar2)
   RETURN SYS_REFCURSOR
AS
   c_fund_list   SYS_REFCURSOR;
   IS_POOLED number := 0;
   VACANT_BUDGET number(10,2):= 0;
   v_code   NUMBER;
   v_errm   VARCHAR2 (64);
     
BEGIN

BEGIN
   SELECT COUNT (*)
     INTO IS_POOLED
     FROM NBBPOSN
    WHERE NBBPOSN_POSN = POSN_NUMBER AND NBBPOSN_TYPE = 'P';
EXCEPTION
   WHEN OTHERS
   THEN
      IS_POOLED := 0;
      v_code := SQLCODE;
      v_errm := SUBSTR (SQLERRM, 1, 64);
      DBMS_OUTPUT.PUT_LINE ('The error code is ' || v_code || '- ' || v_errm);
END;

IF(f_is_vacant_posn(posn_number) = 'Y' OR IS_POOLED > 0 OR futureVacant = 'Y') THEN

VACANT_BUDGET := f_get_budget_vacant_posns(posn_number, fisc_year);

OPEN c_fund_list FOR

SELECT NBRPLBD_COAS_CODE AS COAS_CODE,
       NBRPLBD_FUND_CODE AS FUND_CODE,
       NBRPLBD_ORGN_CODE AS ORGN_CODE,
       NBRPLBD_ACCT_CODE AS ACCT_CODE,
       NBRPLBD_PROG_CODE AS PROG_CODE,
       NBRPLBD_PERCENT AS PERCENT,
       (NBRPLBD_PERCENT * VACANT_BUDGET) / 100 AS BUDGET
  FROM NBRPLBD
 WHERE     NBRPLBD_POSN = POSN_NUMBER
       AND NBRPLBD_FISC_CODE = FISC_YEAR
       AND NBRPLBD_PERCENT <> 0;

ELSE

OPEN c_fund_list FOR

SELECT NBRJLBD_COAS_CODE AS COAS_CODE,
       NBRJLBD_FUND_CODE AS FUND_CODE,
       NBRJLBD_ORGN_CODE AS ORGN_CODE,
       NBRJLBD_ACCT_CODE AS ACCT_CODE,
       NBRJLBD_PROG_CODE AS PROG_CODE,       
       NBRJLBD_PERCENT AS PERCENT,
       (NBRJOBS_ANN_SALARY * NBRJLBD_PERCENT) / 100 AS BUDGET
  FROM NBRJLBD P1, NBRJOBS T1, NBRBJOB
 WHERE     P1.NBRJLBD_POSN = POSN_NUMBER
       AND T1.NBRJOBS_POSN = P1.NBRJLBD_POSN
       AND T1.NBRJOBS_PIDM = P1.NBRJLBD_PIDM
       AND T1.NBRJOBS_STATUS = 'A'
       AND T1.NBRJOBS_SUFF = P1.NBRJLBD_SUFF
       AND NBRBJOB_POSN = P1.NBRJLBD_POSN
       AND NBRBJOB_PIDM = P1.NBRJLBD_PIDM 
       AND P1.NBRJLBD_SUFF = suff
       AND NBRBJOB_CONTRACT_TYPE <> ('O')
       AND ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))       
       AND P1.NBRJLBD_SUFF = NBRBJOB_SUFF
       AND P1.NBRJLBD_CHANGE_IND = 'A'
       AND P1.NBRJLBD_EFFECTIVE_DATE =
              (SELECT MAX (P11.NBRJLBD_EFFECTIVE_DATE)
                 FROM NBRJLBD P11
                WHERE     P11.NBRJLBD_POSN = P1.NBRJLBD_POSN
		      AND P11.NBRJLBD_SUFF = P1.NBRJLBD_SUFF
                      AND P11.NBRJLBD_EFFECTIVE_DATE <= to_date(EffDate,'MM/dd/yyyy')) 
       AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (T11.NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE);

END IF;

  RETURN c_fund_list;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return c_fund_list;
     WHEN OTHERS THEN
       RAISE;

END f_get_funding_info;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_curr_posn_complete
-- PRODUCT....: HR/Reclassification
-- USAGE......: get current position info based on transaction number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return current position info based on transaction number for
-- Approval complete status records 
--------------------------------------------------------------------------------------------

FUNCTION f_get_curr_posn_complete (pass_trans_id VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_posn_list SYS_REFCURSOR; 
   pidm number(8);
BEGIN

BEGIN
SELECT CURR_POSN_SUPERVISOR
  INTO pidm
  FROM TT_HR_PASS.NC_PASS_TRANS_B
 WHERE trans_no = pass_trans_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      pidm := NULL;     
END;

IF pidm is null THEN

OPEN c_posn_list FOR

SELECT NULL AS SPRIDEN_LAST_NAME,
       NULL AS SPRIDEN_MI,
       NULL AS SPRIDEN_FIRST_NAME,
       NULL AS SPRIDEN_ID,
       CURR_PCLS_CODE AS PCLS_CODE,
       CURR_PCLS_DESC AS PCLS_DESC,
       CURR_ECLS_CODE AS ECLS_CODE,
       CURR_POSN_SINGLE AS POSN_SINGLE,
       CURR_POSN_JOB_TYPE AS POSN_JOB_TYPE,
       EMPLOYEE_PIDM AS POSN_PIDM,
       CURR_POSN_SUFF AS POSN_SUFF,
       CURR_PAY_ID AS POSN_PAY_ID,
       CURR_POSN_CHART AS POSN_CHART,
       CURR_POSN_ORGN_CODE AS POSN_ORGN,
       CURR_POSN_ORGN_TITLE AS POSN_ORGN_DESC,
       CURR_POSN_SUPERVISOR AS POSN_SUP_PIDM,
       CURR_POSN_FTE AS POSN_FTE,
       CURR_POSN_PAY_GRADE AS POSN_PAY_GRADE,
       CURR_POSN_ANN_SAL AS POSN_ANN_SAL,
       CURR_POSN_JCRE_CODE AS PCLS_JCRE_CODE
  FROM TT_HR_PASS.NC_PASS_TRANS_B
 WHERE trans_no = pass_trans_id;

ELSE

OPEN c_posn_list FOR

SELECT SPRIDEN_LAST_NAME,
       SPRIDEN_MI,
       SPRIDEN_FIRST_NAME,
       SPRIDEN_ID,
       CURR_PCLS_CODE AS PCLS_CODE,
       CURR_PCLS_DESC AS PCLS_DESC,
       CURR_ECLS_CODE AS ECLS_CODE,
       CURR_POSN_SINGLE AS POSN_SINGLE,
       CURR_POSN_JOB_TYPE AS POSN_JOB_TYPE,       
       EMPLOYEE_PIDM AS POSN_PIDM,
       CURR_POSN_SUFF AS POSN_SUFF,      
       CURR_PAY_ID AS POSN_PAY_ID,
       CURR_POSN_CHART AS POSN_CHART, 
       CURR_POSN_ORGN_CODE AS POSN_ORGN,
       CURR_POSN_ORGN_TITLE AS POSN_ORGN_DESC,
       CURR_POSN_SUPERVISOR AS POSN_SUP_PIDM,
       CURR_POSN_FTE AS POSN_FTE,
       CURR_POSN_PAY_GRADE AS POSN_PAY_GRADE,
       CURR_POSN_ANN_SAL AS POSN_ANN_SAL,
       CURR_POSN_JCRE_CODE AS PCLS_JCRE_CODE
  FROM SPRIDEN,
       TT_HR_PASS.NC_PASS_TRANS_B
 WHERE trans_no = pass_trans_id
  AND CURR_POSN_SUPERVISOR = SPRIDEN_PIDM
  AND SPRIDEN_CHANGE_IND IS NULL;

END IF;
  
RETURN c_posn_list;

END f_get_curr_posn_complete;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_vacant_positions_info
-- PRODUCT....: HR/Reclassification
-- USAGE......: get vacant positions information based on FOP
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return vacant positions information based on FOP
--------------------------------------------------------------------------------------------

FUNCTION f_get_vacant_positions_info (
         coas_code VARCHAR2,
         fund_code VARCHAR2,
         org_code VARCHAR2,
         acct_code VARCHAR2,
         prog_code VARCHAR2,
         fiscal_year VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_vacant_list   SYS_REFCURSOR;
   valid_acct varchar2(6) default null;

BEGIN

BEGIN
SELECT t1.FTVACCT_ACCT_CODE_POOL
  INTO valid_acct
  FROM ftvacct t1
 WHERE t1.ftvacct_coas_code = coas_code AND t1.ftvacct_acct_code = acct_code
 and t1.ftvacct_eff_date in(select max(t11.ftvacct_eff_date) from ftvacct t11
 where t1.ftvacct_acct_code = t11.ftvacct_acct_code
 and t1.ftvacct_coas_code = t11.ftvacct_coas_code and t11.ftvacct_eff_date <= sysdate); 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      valid_acct := null;
END;

IF valid_acct = '6003' THEN

OPEN c_vacant_list FOR

select distinct nbrplbd_posn as posn,
	        nbbposn_pcls_code as pcls_code, 
	        nbbposn_ecls_code as ecls_code,
                nbbposn_title as posn_title,
                t1.nbrptot_fte as posn_fte,
                (t1.nbrptot_fte * NBRPLBD_PERCENT) as fte_fop,
                nbbposn_status as posn_status,
                NBBPOSN_TYPE as posn_type,
                NBRPLBD_BUDGET as amt_budget,
                NBRPLBD_PERCENT as pct_fop,
	        NBRPTOT_BASE_UNITS as pay_id                
from nbrplbd, nbbposn, nbrptot t1, ftvacct
where nbrplbd_coas_code = coas_code and nbrplbd_fund_code = fund_code
and nbrplbd_orgn_code = org_code
--and nbrplbd_acct_code = acct_code
and nbrplbd_prog_code = prog_code
and NBRPLBD_FISC_CODE = fiscal_year
and NBRPLBD_PERCENT <> 0
and nbbposn_status in('A','F')
and nbbposn_posn = nbrplbd_posn
and t1.nbrptot_posn = nbrplbd_posn
and t1.NBRPTOT_FISC_CODE = NBRPLBD_FISC_CODE
and ftvacct_coas_code = nbrplbd_coas_code
AND ftvacct_acct_code = nbrplbd_acct_code
and ftvacct_acct_code_pool = '6003'
and nbrplbd_posn in
(select distinct (t.NBRPTOT_POSN) 
from( 
select NVL (jobs_info.job_count, 0) cjob_count, 
       NVL (jobs_info.job_fte, 0) cjob_fte, 
       pb.* 
  from nbrptot pb
       left join
        (
        select nbrjobs_posn, count(*) job_count,
        sum(t1.nbrjobs_fte) job_fte
        from nbrjobs t1 where 
        t1.nbrjobs_status <> 'T' 
        AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE) 
        group by nbrjobs_posn) jobs_info
        on PB.NBRPTOT_POSN = jobs_info.nbrjobs_posn
  where PB.NBRPTOT_STATUS = 'A') t
where (t.cjob_count = 0 OR t.nbrptot_fte > cjob_fte));   


ELSE 

OPEN c_vacant_list FOR

select distinct nbrplbd_posn as posn,
		nbbposn_pcls_code as pcls_code,
		nbbposn_ecls_code as ecls_code,
                nbbposn_title as posn_title,
                t1.nbrptot_fte as posn_fte,
                (t1.nbrptot_fte * NBRPLBD_PERCENT) as fte_fop,
                nbbposn_status as posn_status,
                NBBPOSN_TYPE as posn_type,
                NBRPLBD_BUDGET as amt_budget,
                NBRPLBD_PERCENT as pct_fop,
            NBRPTOT_BASE_UNITS as pay_id
from nbrplbd, nbbposn, nbrptot t1, ftvacct
where nbrplbd_coas_code = coas_code and nbrplbd_fund_code = fund_code
and nbrplbd_orgn_code = org_code
--and nbrplbd_acct_code = acct_code
and nbrplbd_prog_code = prog_code
and NBRPLBD_FISC_CODE = fiscal_year
and NBRPLBD_PERCENT <> 0
and nbbposn_status in('A','F')
and nbbposn_posn = nbrplbd_posn
and t1.nbrptot_posn = nbrplbd_posn
and t1.NBRPTOT_FISC_CODE = NBRPLBD_FISC_CODE
and ftvacct_coas_code = nbrplbd_coas_code
AND ftvacct_acct_code = nbrplbd_acct_code
and ftvacct_acct_code_pool <> '6003'
and nbrplbd_posn in
(select distinct (t.NBRPTOT_POSN)
from(
select NVL (jobs_info.job_count, 0) cjob_count,
       NVL (jobs_info.job_fte, 0) cjob_fte,
       pb.*
  from nbrptot pb
       left join
        (
        select nbrjobs_posn, count(*) job_count,
        sum(t1.nbrjobs_fte) job_fte
        from nbrjobs t1 where
        t1.nbrjobs_status <> 'T'
        AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
        group by nbrjobs_posn) jobs_info
        on PB.NBRPTOT_POSN = jobs_info.nbrjobs_posn
  where PB.NBRPTOT_STATUS = 'A') t
where (t.cjob_count = 0 OR t.nbrptot_fte > cjob_fte));

END IF;

RETURN c_vacant_list;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return c_vacant_list;
     WHEN OTHERS THEN
       RAISE;
END f_get_vacant_positions_info;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_prev_incumbent
-- PRODUCT....: HR/Reclassification
-- USAGE......: get previous incumbent info based on position number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return previous incumbent info based on position number.
--------------------------------------------------------------------------------------------

FUNCTION f_get_prev_incumbent (posn VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_emp_list   SYS_REFCURSOR;
   v_code   NUMBER;
   v_errm   VARCHAR2 (64);

BEGIN


OPEN c_emp_list FOR

select distinct spriden_id,spriden_pidm,spriden_first_name, spriden_last_name,spriden_mi
from spriden where spriden_change_ind is null and spriden_pidm in(
select t1.nbrjobs_pidm from nbrjobs t1 where nbrjobs_posn = posn 
    and t1.nbrjobs_status = 'T'
    and t1.nbrjobs_effective_date =
            (select max (t11.nbrjobs_effective_date)
                from nbrjobs t11
                 where t11.nbrjobs_pidm = t1.nbrjobs_pidm
           and t11.nbrjobs_posn = t1.nbrjobs_posn));  

RETURN c_emp_list;

EXCEPTION    
    WHEN NO_DATA_FOUND
      THEN
         v_code := SQLCODE;
         v_errm := SUBSTR (SQLERRM, 1, 64);
         DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);
        return c_emp_list;

END f_get_prev_incumbent;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_getPassRequestListByIDs
-- PRODUCT....: HR
-- USAGE......: Get request by originator pidm for PASS
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- This function will join Transaction table with pwvorgn  and FWVATUE to return originator and employee details and org title for PASS application based on originator pidm.
--------------------------------------------------------------------------------------------

FUNCTION f_getPassRequestListByIDs(requestIds VARCHAR2) RETURN SYS_REFCURSOR AS c_nc_pass_trans_b SYS_REFCURSOR;
        BEGIN
            OPEN c_nc_pass_trans_b FOR
    SELECT T1.TRANS_NO, T1.TRANS_STATUS, T1.POSN_NBR,T1.POSN_COAS_CODE, T1.POSN_ORGN_CODE,
          TO_CHAR(T1.POSN_EFFECTIVE_DATE, 'MM/DD/YYYY HH:MI:SS AM') as POSN_EFFECTIVE_DATE,
         T2.fwvatue_first_name || ' ' || T2.fwvatue_last_name || ' '|| t2.fwvatue_spriden_id
            AS originator_name,
         t3.PWVORGN_ORGN_CODE || '-' || t3.PWVORGN_ORGN_TITLE
            AS orgn,
         T4.fwvatue_first_name || ' ' || T4.fwvatue_last_name || ' '|| t4.fwvatue_spriden_id AS employee_name,
         T1.POSN_PCLS_CODE || '-' || T1.POSN_EXTENDED_TITLE
            AS posn_title
    FROM tt_hr_pass.nc_pass_trans_b T1
         LEFT JOIN TTUFISCAL.FWVATUE T2 ON T2.FWVATUE_PIDM = T1.ORIGINATOR_PIDM
         LEFT JOIN TTUFISCAL.PWVORGN T3 ON T3.PWVORGN_ORGN_CODE = T1.POSN_ORGN_CODE
               AND T3.PWVORGN_COAS_CODE = T1.POSN_COAS_CODE
         LEFT JOIN TTUFISCAL.FWVATUE T4 ON T4.FWVATUE_PIDM = T1.EMPLOYEE_PIDM
      WHERE t1.trans_id IN
       (SELECT regexp_substr(requestIds, '[^,]+', 1, LEVEL)
        FROM   dual
        CONNECT BY regexp_substr(requestIds, '[^,]+', 1, LEVEL) IS NOT NULL);
    RETURN c_nc_pass_trans_b;
   END f_getPassRequestListByIDs;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_budget_bd_pool
-- PRODUCT....: HR/Reclassification
-- USAGE......: get budget pool and balance acct code based on chart and fund
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return budget pool and balance acct code based on chart and fund
--------------------------------------------------------------------------------------------

FUNCTION f_get_budget_bd_pool (chart varchar2 , fundcode varchar2, acctCode VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_budget  SYS_REFCURSOR;

BEGIN

      open c_budget for
      
      
SELECT ftvacct_acct_code_pool as bdPool, nwbbrfp_bal_acct_code as balAcctCode
  FROM TTUFISCAL.NWBBRFP, FTVACCT t1
 WHERE     nwbbrfp_coas_code =  chart
       AND nwbbrfp_fund_code_int_start <= fundcode
       AND nwbbrfp_fund_code_int_end >=  fundcode
       AND nwbbrfp_status = 'A'
       AND nwbbrfp_effective_date <= SYSDATE
       AND t1.ftvacct_acct_code = acctCode
       AND t1.FTVACCT_ACCT_CODE_POOL = nwbbrfp_sal_ACCT_CODE
       AND t1.ftvacct_coas_code = nwbbrfp_coas_code
       AND t1.ftvacct_eff_date =
              (SELECT MAX (t11.ftvacct_eff_date)
                 FROM ftvacct t11
                WHERE     t1.ftvacct_acct_code = t11.ftvacct_acct_code
                      AND t1.ftvacct_coas_code = t11.ftvacct_coas_code
                      AND t11.ftvacct_eff_date <= SYSDATE);
      
    RETURN c_budget;

END  f_get_budget_bd_pool;   

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_is_last_analyst
-- PRODUCT....: HR/Reclassification
-- USAGE......: get last analyst for jv records.
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return last analyst for jv records.
--------------------------------------------------------------------------------------------

FUNCTION f_is_last_analyst (transId VARCHAR2, analystId VARCHAR2)
   RETURN NUMBER
AS
   countAnalyst   NUMBER := 0;
BEGIN
   SELECT COUNT (rc.jvrc_analyst_user_id)
     INTO countAnalyst
     FROM tt_hr_pass.nc_pass_jvrc_b rc, tt_hr_pass.nc_pass_jvappr_b ap
    WHERE     rc.JVRC_TRANSACTION_NO = transId
          AND ap.JVAPPR_TRANSACTION_NO = rc.JVRC_TRANSACTION_NO
          AND ap.JVAPPR_GATEWAY_IND IS NULL
          AND (   rc.jvrc_analyst_user_id IS NULL
               OR rc.jvrc_analyst_user_id != analystId)
          AND rc.jvrc_analyst_user_id != 'LOSING';

   RETURN countAnalyst;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      RETURN countAnalyst;
   WHEN OTHERS
   THEN
      RAISE;
END f_is_last_analyst;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_locked_records
-- PRODUCT....: HR/Reclassification
-- USAGE......: get  locked analyst, spriden first and last name
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return locked analyst, spriden first and last name
--------------------------------------------------------------------------------------------

FUNCTION f_check_locked_records (transId VARCHAR2, analystId VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_lock   SYS_REFCURSOR;
BEGIN
   OPEN c_lock FOR
   
      SELECT rc.jvrc_locked_analyst, spriden_first_name, spriden_last_name
        FROM tt_hr_pass.nc_pass_jvrc_b rc, spriden
       WHERE     rc.jvrc_transaction_no = transid
             AND rc.jvrc_locked_analyst IS NOT NULL
             AND spriden_id = rc.jvrc_locked_analyst
             AND rc.jvrc_locked_analyst != analystid
             AND spriden_change_ind IS NULL;


   RETURN c_lock;
END f_check_locked_records;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_acct_code_info
-- PRODUCT....: HR/New Position
-- USAGE......: get acct code based on chart
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return acct code based on chart
--------------------------------------------------------------------------------------------

FUNCTION f_get_acct_code_info (chart VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   c_acct_list SYS_REFCURSOR;

BEGIN

OPEN c_acct_list FOR

select ftvacct_acct_code
  from ftvacct
 where ftvacct_coas_code = chart and ftvacct_data_entry_ind = 'B';
   
RETURN c_acct_list;

END f_get_acct_code_info;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_future_eff_record
-- PRODUCT....: HR
-- USAGE......: check future effective record
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return a list of pay range for the given chart code and position class
--------------------------------------------------------------------------------------------

FUNCTION F_CHECK_FUTURE_EFF_RECORD (chartCode  VARCHAR2, posnNum VARCHAR2)
   RETURN SYS_REFCURSOR
AS
   C_FUTURE_RECORD       SYS_REFCURSOR;
   V_JLBD_EFF_DATE   DATE;
   V_JOBS_EFF_DATE   DATE;
   V_EARN_EFF_DATE   DATE;
   v_code   NUMBER;
   v_errm   VARCHAR2 (64);
BEGIN
   BEGIN
      
   SELECT NBRJLBD_EFFECTIVE_DATE
     INTO V_JLBD_EFF_DATE
     FROM (  SELECT *
               FROM NBRJLBD
              WHERE NBRJLBD_POSN = posnNum AND NBRJLBD_COAS_CODE = chartCode
           ORDER BY NBRJLBD_EFFECTIVE_DATE DESC)
    WHERE ROWNUM = 1;
    
   EXCEPTION
      WHEN OTHERS
      THEN
         V_JLBD_EFF_DATE := null;
         v_code := SQLCODE;
         v_errm := SUBSTR (SQLERRM, 1, 64);
         DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);
   END;


   BEGIN
      
   SELECT NBRJOBS_EFFECTIVE_DATE
     INTO V_JOBS_EFF_DATE
     FROM (  SELECT *
               FROM NBRJOBS
              WHERE NBRJOBS_POSN = posnNum AND NBRJOBS_COAS_CODE_TS = chartCode
           ORDER BY NBRJOBS_EFFECTIVE_DATE DESC)
    WHERE ROWNUM = 1;
    
   EXCEPTION
      WHEN OTHERS
      THEN
         V_JOBS_EFF_DATE := null;
         v_code := SQLCODE;
         v_errm := SUBSTR (SQLERRM, 1, 64);
         DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);
   END;
    
   BEGIN
      
   SELECT NBREARN_EFFECTIVE_DATE
     INTO V_EARN_EFF_DATE
     FROM (  SELECT *
               FROM NBREARN
              WHERE NBREARN_posn = posnNum
           ORDER BY NBREARN_EFFECTIVE_DATE DESC)
    WHERE ROWNUM = 1;

    
   EXCEPTION
      WHEN OTHERS
      THEN
         V_EARN_EFF_DATE := null;
         v_code := SQLCODE;
         v_errm := SUBSTR (SQLERRM, 1, 64);
         DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);
   END;


   OPEN C_FUTURE_RECORD FOR 
   SELECT V_JLBD_EFF_DATE as JLBD_EFF_DATE, 
          V_JOBS_EFF_DATE as JOBS_EFF_DATE, 
          V_EARN_EFF_DATE as EARN_EFF_DATE 
   FROM DUAL;

   RETURN C_FUTURE_RECORD;

END F_CHECK_FUTURE_EFF_RECORD;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_valid_jv_fund
-- PRODUCT....: HR
-- USAGE......: check valid jv fund for chart, fund code and effective date
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return jv fund for chart, fund code and effective date
--------------------------------------------------------------------------------------------

function f_check_valid_jv_fund(
     coas_code  varchar2,
     fund_code  varchar2,     
     effe_date  DATE)
     return varchar2
  as
     valid_fund varchar2(9) default null;     

BEGIN

SELECT t1.FTVFUND_FUND_CODE
  INTO valid_fund
  FROM FTVFUND t1
 WHERE  t1.FTVFUND_DATA_ENTRY_IND = 'Y'
       and t1.FTVFUND_STATUS_IND = 'A'
       and (trunc(t1.FTVfund_TERM_DATE) >= effe_date or t1.FTVfund_TERM_DATE IS NULL)
       and t1.FTVFUND_COAS_CODE = coas_code
       and t1.FTVFUND_fund_code = fund_code
       and t1.FTVFUND_EFF_DATE = (SELECT max(t11.FTVFUND_EFF_DATE)
                                   FROM FTVFUND t11
                                   where t1.ftvfund_FUND_code = t11.ftvfund_fund_code
                                   and t1.ftvfund_coas_code = t11.ftvfund_coas_code
                                   and trunc(t11.ftvfund_eff_date) <= effe_date);


return valid_fund;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return valid_fund;
     WHEN OTHERS THEN
       RAISE;

END f_check_valid_jv_fund;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_valid_jv_orgn
-- PRODUCT....: HR
-- USAGE......: check valid jv orgn for chart, orgn code and effective date
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return jv orgn for chart, orgn code and effective date
--------------------------------------------------------------------------------------------

function f_check_valid_jv_orgn(
     coas_code  varchar2,
     orgn_code  varchar2,     
     effe_date  DATE)
     return varchar2
  as
     valid_orgn varchar2(9) default null;     

BEGIN

SELECT t1.FTVORGN_ORGN_CODE
  INTO valid_orgn
  FROM FTVORGN t1
 WHERE  t1.FTVORGN_DATA_ENTRY_IND = 'Y'
       and t1.FTVORGN_STATUS_IND = 'A'
       and (trunc(t1.FTVORGN_TERM_DATE) >= effe_date or t1.FTVORGN_TERM_DATE IS NULL)
       and t1.FTVORGN_COAS_CODE = coas_code
       and t1.FTVORGN_ORGN_code = orgn_code
       and t1.FTVORGN_EFF_DATE = (SELECT max(t11.FTVORGN_EFF_DATE)
                                   FROM FTVORGN t11
                                   where t1.ftvorgn_orgn_code = t11.ftvorgn_orgn_code
                                   and t1.ftvorgn_coas_code = t11.ftvorgn_coas_code
                                   and trunc(t11.ftvorgn_eff_date) <= effe_date);


return valid_orgn;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return valid_orgn;
     WHEN OTHERS THEN
       RAISE;

END f_check_valid_jv_orgn;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_valid_jv_acct
-- PRODUCT....: HR
-- USAGE......: check valid jv acct for chart, acct code and effective date
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return jv acct for chart, acct code and effective date
--------------------------------------------------------------------------------------------

function f_check_valid_jv_acct(
     coas_code  varchar2,
     acct_code  varchar2,
     effe_date  DATE)
     return varchar2
  as
     valid_acct varchar2(9) default null;     

BEGIN

SELECT t1.FTVACCT_ACCT_CODE
  INTO valid_acct
  FROM FTVACCT t1
 WHERE  t1.FTVACCT_DATA_ENTRY_IND = 'B'
       and t1.FTVACCT_STATUS_IND = 'A'
       and (trunc(t1.FTVACCT_TERM_DATE) >= effe_date or t1.FTVACCT_TERM_DATE IS NULL)
       and t1.FTVACCT_COAS_CODE = coas_code
       and t1.FTVACCT_ACCT_code = acct_code
       and t1.FTVACCT_EFF_DATE = (SELECT max(t11.FTVACCT_EFF_DATE)
                                   FROM FTVACCT t11
                                   where t1.ftvacct_acct_code = t11.ftvacct_acct_code
                                   and t1.ftvacct_coas_code = t11.ftvacct_coas_code
                                   and trunc(t11.FTVACCT_EFF_DATE) <= effe_date);


return valid_acct;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return valid_acct;
     WHEN OTHERS THEN
       RAISE;

END f_check_valid_jv_acct;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_check_valid_jv_prog
-- PRODUCT....: HR
-- USAGE......: check valid jv prog for chart, prog code and effective date
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return jv prog for chart, prog code and effective date
--------------------------------------------------------------------------------------------

function f_check_valid_jv_prog(
     coas_code  varchar2,
     prog_code  varchar2,
     effe_date  DATE)
     return varchar2
  as
     valid_prog varchar2(9) default null;     

BEGIN

SELECT t1.FTVPROG_PROG_CODE
  INTO valid_prog
  FROM FTVPROG t1
 WHERE  t1.FTVPROG_DATA_ENTRY_IND = 'Y'
       and t1.FTVPROG_STATUS_IND = 'A'
       and (trunc(t1.FTVPROG_TERM_DATE) >= effe_date or t1.FTVPROG_TERM_DATE IS NULL)
       and t1.FTVPROG_COAS_CODE = coas_code
       and t1.FTVPROG_PROG_code = prog_code
       and t1.FTVPROG_EFF_DATE = (SELECT max(t11.FTVPROG_EFF_DATE)
                                   FROM FTVPROG t11
                                   where t1.ftvprog_prog_code = t11.ftvprog_prog_code
                                   and t1.ftvprog_coas_code = t11.ftvprog_coas_code
                                   and trunc(t11.ftvprog_eff_date) <= effe_date);

return valid_prog;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return valid_prog;
     WHEN OTHERS THEN
       RAISE;

END f_check_valid_jv_prog;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: get_available_balance
-- PRODUCT....: HR
-- USAGE......: Get available balance
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return bavl available balance.
--------------------------------------------------------------------------------------------

function f_get_available_balance(
     coas_code  varchar2,
     fund_code  varchar2,
     orgn_code  varchar2,
     prog_code  varchar2,
     acct_code  varchar2,
     fiscal_year varchar2)
  return number
  as
     avail_blnce number default 0;
     avail_blnce_1 number default 0;
     avail_blnce_2 number default 0;
     bal_acct varchar2(9) default null; 
     v_code  NUMBER;
     v_errm  VARCHAR2 (64);

BEGIN

IF(coas_code = 'T' or coas_code = 'S') THEN 

BEGIN

SELECT SUM (FGBBAVL_SUM_ADOPT_BUD + FGBBAVL_SUM_BUD_ADJT - FGBBAVL_SUM_YTD_ACTV - FGBBAVL_SUM_ENCUMB- FGBBAVL_SUM_BUD_RSRV)
   INTO avail_blnce
 FROM fgbbavl
 WHERE     fgbbavl_coas_code = coas_code
       AND fgbbavl_fund_code = fund_code
       AND fgbbavl_orgn_code = orgn_code
       AND fgbbavl_prog_code = prog_code       
       AND fgbbavl_fsyr_code = fiscal_year;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      avail_blnce := 0;
      v_code := SQLCODE;
      v_errm := SUBSTR (SQLERRM, 1, 64);
      DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);
END;
       
ELSE

--SELECT SUM (FGBBAVL_SUM_ADOPT_BUD + FGBBAVL_SUM_BUD_ADJT - FGBBAVL_SUM_YTD_ACTV - FGBBAVL_SUM_ENCUMB- FGBBAVL_SUM_BUD_RSRV)
--   INTO avail_blnce
-- FROM fgbbavl
-- WHERE     fgbbavl_coas_code = coas_code
--       AND fgbbavl_fund_code = fund_code
--       AND fgbbavl_orgn_code = orgn_code
--       AND fgbbavl_prog_code = prog_code
--       AND fgbbavl_acct_code = acct_code
--       AND fgbbavl_fsyr_code = fiscal_year;

      BEGIN
         SELECT nwbbrfp_bal_acct_code,
                NVL ((FGBOPAL_14_ADOPT_BUD + FGBOPAL_14_BUD_ADJT - FGBOPAL_14_YTD_ACTV - FGBOPAL_14_ENCUMB - FGBOPAL_14_BUD_RSRV),0)
           INTO bal_acct, avail_blnce_1
           FROM TTUFISCAL.NWBBRFP, FTVACCT t1, fgbopal
          WHERE     nwbbrfp_coas_code = coas_code
                AND nwbbrfp_fund_code_int_start <= fund_code
                AND nwbbrfp_fund_code_int_end >= fund_code
                AND nwbbrfp_status = 'A'
                AND nwbbrfp_effective_date <= SYSDATE
                AND t1.ftvacct_acct_code = acct_code
                AND t1.FTVACCT_ACCT_CODE_POOL = nwbbrfp_sal_ACCT_CODE
                AND t1.ftvacct_coas_code = nwbbrfp_coas_code
                AND t1.ftvacct_eff_date =
                       (SELECT MAX (t11.ftvacct_eff_date)
                          FROM ftvacct t11
                         WHERE     t1.ftvacct_acct_code =
                                      t11.ftvacct_acct_code
                               AND t1.ftvacct_coas_code =
                                      t11.ftvacct_coas_code
                               AND t11.ftvacct_eff_date <= SYSDATE)
                AND fgbopal_coas_code(+) = coas_code
                AND fgbopal_fund_code(+) = fund_code
                AND fgbopal_orgn_code(+) = orgn_code
                AND fgbopal_acct_code(+) = nwbbrfp_bal_acct_code
                AND fgbopal_prog_code(+) = prog_code
                AND fgbopal_fsyr_code(+) = fiscal_year;
      EXCEPTION
         WHEN OTHERS
         THEN
            avail_blnce_1 := 0;
            v_code := SQLCODE;
            v_errm := SUBSTR (SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE (
               'The error code is ' || v_code || '- ' || v_errm);
      END;


      BEGIN
         SELECT NVL (SUM (FGBOPAL_14_ADOPT_BUD + FGBOPAL_14_BUD_ADJT - FGBOPAL_14_YTD_ACTV - FGBOPAL_14_ENCUMB - FGBOPAL_14_BUD_RSRV),0)
           INTO avail_blnce_2
           FROM ftvacct t1, fgbopal
          WHERE     t1.FTVACCT_ACCT_CODE_POOL = bal_acct
                AND t1.ftvacct_coas_code = coas_code
                AND t1.ftvacct_eff_date =
                       (SELECT MAX (t11.ftvacct_eff_date)
                          FROM ftvacct t11
                         WHERE     t1.ftvacct_acct_code =
                                      t11.ftvacct_acct_code
                               AND t1.ftvacct_coas_code =
                                      t11.ftvacct_coas_code
                               AND t11.ftvacct_eff_date <= SYSDATE)
                AND fgbopal_coas_code = coas_code
                AND fgbopal_fund_code = fund_code
                AND fgbopal_orgn_code = orgn_code
                AND fgbopal_acct_code = t1.ftvacct_acct_code
                AND fgbopal_prog_code = prog_code
                AND fgbopal_fsyr_code = fiscal_year;
      EXCEPTION
         WHEN OTHERS
         THEN
            avail_blnce_2 := 0;
            v_code := SQLCODE;
            v_errm := SUBSTR (SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE (
               'The error code is ' || v_code || '- ' || v_errm);
      END;

      avail_blnce := avail_blnce_1 + avail_blnce_2;

END IF;  

return avail_blnce;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return avail_blnce;
     WHEN OTHERS THEN
       RAISE;
END f_get_available_balance;



--------------------------------------------------------------------------------------------
-- OBJECT NAME: PosnNumValid
-- PRODUCT....: HR
-- USAGE......: Returns if a posn number is valid for PASS
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- 
--------------------------------------------------------------------------------------------

FUNCTION posnNumValid(chartcode VARCHAR2, posnNumber VARCHAR2) RETURN NUMERIC IS
    v_indexFound NUMERIC := 0;
    BEGIN
      SELECT COUNT(*) INTO v_indexFound
        FROM NBBPOSN
        WHERE NBBPOSN_COAS_CODE = chartcode
        AND NBBPOSN_POSN = chartCode || posnNumber;
      RETURN v_indexFound;
    END posnNumValid;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: GetNextPosnCode
-- PRODUCT....: HR
-- USAGE......: Generate next POSN number for PASS
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Jaya Maheshwaran
--
-- DESCRIPTION:
--
-- 
--------------------------------------------------------------------------------------------
FUNCTION GetNextPosnCode(chartCode VARCHAR2, posnNumber VARCHAR2) RETURN VARCHAR2 IS
  v_nextPosnNumber VARCHAR2(6);
  tempPosnNumber NUMERIC := 0;
  posnNumberValid NUMERIC := 1;
BEGIN
  tempPosnNumber := to_number(SUBSTR(posnNumber, 2));
  LOOP
    tempPosnNumber := tempPosnNumber - 1;
    v_nextPosnNumber := chartCode || tempPosnNumber;
    posnNumberValid := TT_HR_PASS.NWKPASS.posnNumValid(chartCode, to_char(tempPosnNumber));
    EXIT WHEN posnNumberValid = 0;
  END LOOP;
 RETURN v_nextPosnNumber;
END GetNextPosnCode;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_insert_holding_table
-- PRODUCT....: HR
-- USAGE......: Inserts records in holding table for budget JV section
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will inserts records in holding table for budget JV section
--------------------------------------------------------------------------------------------

FUNCTION f_insert_holding_table (recType          VARCHAR2,
                                 submissionNo     VARCHAR2,
                                 systemId         VARCHAR2,
                                 userId           VARCHAR2,
                                 transNo          VARCHAR2,
                                 transDate        VARCHAR2,
                                 budgetPeriod     VARCHAR2,
                                 ruleClassCode    VARCHAR2,
                                 coasCode         VARCHAR2,
                                 fundCode         VARCHAR2,
                                 orgnCode         VARCHAR2,
                                 acctCode         VARCHAR2,
                                 progCode         VARCHAR2,
                                 amount           VARCHAR2,
                                 drCrInd          VARCHAR2,
                                 description      VARCHAR2)
   RETURN NUMBER
IS
   v_holdingRecordAdded NUMBER default 0;

BEGIN

   INSERT INTO TTUFISCAL.NWRJVHD (nwrjvhd_rec_type,
                                  nwrjvhd_submission_no,
                                  nwrjvhd_system_id,
                                  nwrjvhd_user_id,
                                  nwrjvhd_doc_ref_num,
                                  nwrjvhd_trans_date,
                                  nwrjvhd_budget_prd,
                                  nwrjvhd_rule_class_code,
                                  nwrjvhd_coas_code,
                                  nwrjvhd_fund_code,
                                  nwrjvhd_orgn_code,
                                  nwrjvhd_acct_code,
                                  nwrjvhd_prog_code,
                                  nwrjvhd_amount,
                                  nwrjvhd_dr_cr_ind,
                                  nwrjvhd_description)
        VALUES (recType,
                submissionNo,
                systemId,
                userId,
                transNo,
                to_date(transDate, 'MM/dd/yyyy'),
                budgetPeriod,
                ruleClassCode,
                coasCode,
                fundCode,
                orgnCode,
                acctCode,
                progCode,
                amount,
                drCrInd,
                description);

  COMMIT;

  v_holdingRecordAdded := 1;

  RETURN v_holdingRecordAdded;

EXCEPTION   
   WHEN OTHERS
   THEN
      DECLARE
         err_msg VARCHAR2(30000);         
    BEGIN         
       v_holdingRecordAdded := 0;
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('ERR -' ||SQLERRM ||' LINE -'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
       err_msg := ('ERROR in TTUFISCAL.NWRJVHD '||'ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
       insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP,
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','f_insert_holding_table',
                          transNo, userId
                          );                          
    END;
    
    RETURN v_holdingRecordAdded;
END f_insert_holding_table;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_delete_jv_records
-- PRODUCT....: HR
-- USAGE......: deletes jv records of the given transaction number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will deletes jv records of the given transaction number
--------------------------------------------------------------------------------------------

function f_delete_jv_records(trans_no VARCHAR2)
    return number
as
v_holdingRecordDeleted number default 0;

BEGIN

DELETE FROM tt_hr_pass.nc_pass_jvappr_b
WHERE jvappr_transaction_no = trans_no;

COMMIT;

DELETE FROM tt_hr_pass.nc_pass_jvrc_b
WHERE jvrc_transaction_no = trans_no;  

COMMIT;

v_holdingRecordDeleted := 1;

RETURN v_holdingRecordDeleted;

EXCEPTION
    WHEN OTHERS THEN
       return v_holdingRecordDeleted;     
       RAISE;
END f_delete_jv_records;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: P_UPLOAD_JV_RECORDS
-- PRODUCT....: HR
-- USAGE......: upload jv records to holding table
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will push jv records to holding table
--------------------------------------------------------------------------------------------

PROCEDURE P_UPLOAD_JV_RECORDS (
   pass_trans   IN     VARCHAR2,
   posn_nbr   IN     VARCHAR2,
   user_id    IN     VARCHAR2,
   status        OUT VARCHAR2)
IS
   v_pdid            TT_HR_PASS.NC_PASS_TRANS_B.PD_ID%TYPE;
   rec_type          VARCHAR2 (2);
   submission_no     VARCHAR2 (2);
   system_id         VARCHAR2 (15);
   userId            VARCHAR2 (30);
   trans_date        VARCHAR2 (20);
   coas_code         VARCHAR2 (1);
   fund_code         VARCHAR2 (6);
   orgn_code         VARCHAR2 (6);
   acct_code         VARCHAR2 (6);
   prog_code         VARCHAR2 (6);
   amount            VARCHAR2 (30);
   dr_cr_ind         VARCHAR2 (1);
   description       VARCHAR2 (35);
   budget_period     VARCHAR2 (10);
   budget_prd        VARCHAR2 (10);
   rows_added        INTEGER (10) := -1;
   rows_deleted      INTEGER (10) := 0;
   rule_class_code   VARCHAR2 (5);
   v_code NUMBER;
   v_errm VARCHAR2(64);
   pd_status VARCHAR2(4);  
   v_err_msg VARCHAR2(30000);
   v_file varchar2 (300);
   wfile_handle utl_file.file_type;
   v_eprint_user varchar2(90);
   v_one_up integer;

   CURSOR CURSOR_JVS
   IS 
      SELECT jvrc_coas_code as coas_code,
       jvrc_fund_code as fund_code,
       jvrc_orgn_code as orgn_code,
       jvrc_acct_code as acct_code,
       jvrc_prog_code as prog_code,
       jvrc_amount as amount,
       jvrc_dr_cr_ind as dr_cr_ind,
       jvrc_description as description,
       jvrc_trans_date as trans_date,
       jvrc_rule_class_code as rule_class_code
      FROM tt_hr_pass.nc_pass_jvrc_b
      WHERE JVRC_TRANSACTION_NO IN (SELECT distinct jvappr_transaction_no
                                  FROM tt_hr_pass.nc_pass_jvappr_b
                                 WHERE     jvappr_transaction_no = pass_trans
                                       AND UPPER (jvappr_gateway_ind) LIKE
                                              ('SUB%'));   

BEGIN
   FOR jvrecord IN CURSOR_JVS
   LOOP
      BEGIN
         coas_code := jvrecord.coas_code;
         fund_code := jvrecord.fund_code;
         orgn_code := jvrecord.orgn_code;
         acct_code := jvrecord.acct_code;
         prog_code := jvrecord.prog_code;
         amount := jvrecord.amount;
         dr_cr_ind := jvrecord.dr_cr_ind;
         jvrecord.description := REPLACE(jvrecord.description, '#####', SUBSTR(posn_nbr, 2));
         description := jvrecord.description;         
         trans_date := TO_CHAR(jvrecord.trans_date, 'MM/dd/yyyy'); 
         rule_class_code := jvrecord.rule_class_code;
         rec_type := '1';
         submission_no := '0';

         CASE coas_code
            WHEN 'H'
            THEN
               system_id := 'HEPAFLRD';
            WHEN 'E'
            THEN
               system_id := 'EEPAFLRD';
            ELSE
               system_id := 'TBUDPAA';
         END CASE;

         userId := 'TT_HR_EPAF_LRD_APP';
         budget_period :=
            SUBSTR (TO_CHAR (jvrecord.trans_date, 'MM/dd/yyyy'), 1, 2) + 4;

         IF budget_period > 12
         THEN
            budget_period := budget_period - 12;
         END IF;
   
 	 IF budget_period < 10
	 THEN
	 budget_period := '0' || TO_CHAR(budget_period);
	 END IF;

         budget_prd := TO_CHAR (budget_period);

         rows_added :=
            TT_HR_PASS.NWKPASS.f_insert_holding_table (rec_type,
                                                       submission_no,
                                                       system_id,
                                                       userId,
                                                       pass_trans,
                                                       trans_date,
                                                       budget_prd,
                                                       rule_class_code,
                                                       coas_code,
                                                       fund_code,
                                                       orgn_code,
                                                       acct_code,
                                                       prog_code,
                                                       amount,
                                                       dr_cr_ind,
                                                       description);
      EXCEPTION
         WHEN OTHERS
         THEN
            rows_added := 0;
            status := 'error';
            raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
      END;
   END LOOP;

   IF rows_added = 1
   THEN
     status := 'success';   
    --  rows_deleted := TT_HR_PASS.NWKPASS.f_delete_jv_records (pass_trans);
    --  IF rows_deleted = 1 THEN
    --  	status := 'success';    
    --  END IF;
   ELSIF rows_added = -1
   THEN
      status := 'empty';  
   ELSE
      status := 'error'; 
   END IF;  

/*
IF status = 'success' OR status = 'empty'
   THEN
      UPDATE TT_HR_PASS.NC_PASS_TRANS_B
      SET TRANS_STATUS = 'C', USER_ID = user_id, ACTIVITY_DATE = SYSDATE
      WHERE TRANS_NO = pass_trans;
      COMMIT;

       v_err_msg := ('The transaction ' || pass_trans || ' was updated to Approve Complete on '|| SYSDATE ||' by user ' || user_id || ' with rows added and status'|| rows_added || 'and' || status);
       v_file := 'p_pass_approve_complete.xls';
       wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');
       utl_file.put_line(wfile_handle,v_err_msg);
       if utl_file.is_open (wfile_handle) then
       utl_file.fclose (wfile_handle);
       DBMS_OUTPUT.PUT_LINE ('Err File Closed : '||v_file);
       end if;
       select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
       into   v_eprint_user
       from   dual;
       DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

       select gjbpseq.nextval
       into v_one_up
       from DUAL;

       GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
                                ,'p_pass_approve_complete'     -- e-Print Report definition (case sensitive)
                                ,'p_pass_approve_complete.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
                                ,v_eprint_user            -- repository name
                                ,v_eprint_user);          -- user id (same as repository name)
       DBMS_OUTPUT.PUT_LINE('Sending eprint error report');
       DBMS_OUTPUT.PUT_LINE (' Completed.');
             

      BEGIN
         SELECT PD_ID
           INTO v_pdid
           FROM TT_HR_PASS.NC_PASS_TRANS_B
          WHERE TRANS_NO = pass_trans;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_pdid := 0;
            v_code := SQLCODE;
            v_errm := SUBSTR(SQLERRM, 1 , 64);
            DBMS_OUTPUT.PUT_LINE('The error code is ' || v_code || '- ' || v_errm);
      END;
 

      IF (v_pdid != 0)
      THEN
         SELECT pwbpdpd_status
           INTO pd_status
           FROM ttufiscal.pwbpdpd
          WHERE pwbpdpd_id = v_pdid;

    	IF (pd_status = 'PASS') THEN         
          INSERT INTO TTUFISCAL.PWBPDSG(PWBPDSG_ID,PWBPDSG_PWBPDPD_ID,PWBPDSG_USER_ID,PWBPDSG_ACTIVITY_DATE)
          VALUES(TTUFISCAL.PWBPDSG_ID_SEQ.NEXTVAL,v_pdid,user_id,SYSDATE);
          COMMIT;

          UPDATE ttufiscal.pwbpdpd
            SET pwbpdpd_status = 'IP',
                pwbpdpd_posn = posn_nbr,
                pwbpdpd_activity_date = SYSDATE,
                pwbpdpd_user_id = user_id
          WHERE pwbpdpd_id = v_pdid;  
          COMMIT;
        END IF;         
      END IF;
*/

EXCEPTION
   WHEN OTHERS
   THEN
    RAISE;  
    status := 'error';
      v_code := SQLCODE;
      v_errm := SUBSTR(SQLERRM, 1 , 64);
     DBMS_OUTPUT.PUT_LINE('The error code is ' || v_code || '- ' || v_errm);
END;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: P_UPDATE_EPM_PASS_STATUS
-- PRODUCT....: HR
-- USAGE......: updates epm pd status and pass status
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will updates epm pd status and push records to jv table
--------------------------------------------------------------------------------------------

PROCEDURE P_UPDATE_EPM_PASS_STATUS (
   pass_trans   IN     VARCHAR2,
   posn_nbr     IN     VARCHAR2,
   user_id      IN     VARCHAR2,
   status          OUT VARCHAR2)
IS
   v_pdid   TT_HR_PASS.NC_PASS_TRANS_B.PD_ID%TYPE;
   v_code   NUMBER;
   v_errm   VARCHAR2 (64);
   pd_status VARCHAR2(4);
   v_trans_aprv_date  TT_HR_PASS.NC_PASS_TRANS_B.APPROVAL_DATE%TYPE;
BEGIN
   BEGIN
      SELECT PD_ID, APPROVAL_DATE
        INTO v_pdid, v_trans_aprv_date
        FROM TT_HR_PASS.NC_PASS_TRANS_B
       WHERE TRANS_NO = pass_trans;

      IF (v_pdid != 0)
      THEN
         SELECT pwbpdpd_status
           INTO pd_status
           FROM ttufiscal.pwbpdpd
          WHERE pwbpdpd_id = v_pdid;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_pdid := 0;
         v_code := SQLCODE;
         v_errm := SUBSTR (SQLERRM, 1, 64);
         DBMS_OUTPUT.PUT_LINE (
            'The error code is ' || v_code || '- ' || v_errm);
   END;

   IF (pd_status = 'PASS')
      THEN
         INSERT INTO TTUFISCAL.PWBPDSG (PWBPDSG_ID,
                                        PWBPDSG_PWBPDPD_ID,
                                        PWBPDSG_USER_ID,
                                        PWBPDSG_ACTIVITY_DATE)
              VALUES (TTUFISCAL.PWBPDSG_ID_SEQ.NEXTVAL,
                      v_pdid,
                      user_id,
                      SYSDATE);

         COMMIT;

         UPDATE ttufiscal.pwbpdpd
            SET pwbpdpd_status = 'IP',
                pwbpdpd_posn = posn_nbr,
                pwbpdpd_activity_date = SYSDATE,
                pwbpdpd_user_id = user_id
          WHERE pwbpdpd_id = v_pdid;

         COMMIT;
   END IF;

   IF (v_trans_aprv_date IS NOT NULL) THEN
      UPDATE TT_HR_PASS.NC_PASS_TRANS_B
        SET TRANS_STATUS = 'C', USER_ID = user_id, ACTIVITY_DATE = SYSDATE
        WHERE TRANS_NO = pass_trans;
   END IF;

   COMMIT;
   status := 'success';
   
EXCEPTION
   WHEN OTHERS
   THEN
      DECLARE
      err_msg VARCHAR2(30000);	
   BEGIN
      status := 'error';
      ROLLBACK;
      v_code := SQLCODE;
      err_msg := SUBSTR (SQLERRM, 1, 64);
      DBMS_OUTPUT.PUT_LINE ('The error code is ' || v_code || '- ' || v_errm);
      insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP,
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','P_UPDATE_EPM_PASS_STATUS',
                          pass_trans, user_id
                          );	
  END;   
END;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_prev_eval_score
-- PRODUCT....: HR
-- USAGE......: Get previous eval score
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return previous evaluation score to display Reclass HR edit
--------------------------------------------------------------------------------------------

function f_get_prev_eval_score(
     empPidm  varchar2)
  return number
  as
     eval_score number default 0;

BEGIN

SELECT PERREVW_REVT_RATING
  INTO eval_score
  FROM (  SELECT *
            FROM PERREVW
           WHERE PERREVW_PIDM = empPidm AND PERREVW_REVT_COMPLETE = 'Y'
        ORDER BY PERREVW_REVT_DATE DESC)
 WHERE ROWNUM = 1;
 
return eval_score;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return eval_score;
     WHEN OTHERS THEN
       RAISE;
       
END f_get_prev_eval_score;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_6_months_salary
-- PRODUCT....: HR/Reclassification
-- USAGE......: get 6 months salary based on pidm, posn, suff, pict code,effe date, salary, sixmonth_before_salary
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return 6 months salary based on 
--pidm, posn, suff, pict code,effe date, salary, sixmonth_before_salary

--------------------------------------------------------------------------------------------

FUNCTION f_get_6_months_salary (
        PIDM VARCHAR2, 
        POSN varchar2, 
        SUFF varchar2, 
        PICT_CODE varchar2,        
        EffDate varchar2,
        SALARY varchar2,
        SIX_MONTHS_AGO varchar2)
RETURN SYS_REFCURSOR
AS
   c_6_months_sal SYS_REFCURSOR;   

BEGIN

OPEN c_6_months_sal FOR

SELECT to_char(T1.NBRJOBS_EFFECTIVE_DATE, 'MM/dd/yyyy') as NBRJOBS_EFFECTIVE_DATE, T1.NBRJOBS_ANN_SALARY, T1.NBRJOBS_REG_RATE
  FROM NBRJOBS T1
 WHERE     T1.NBRJOBS_PIDM = PIDM
       AND T1.NBRJOBS_POSN = POSN
       AND T1.NBRJOBS_SUFF = SUFF
       AND TRUNC (T1.NBRJOBS_PERS_CHG_DATE) >= to_date(SIX_MONTHS_AGO, 'MM/dd/yyyy')
       AND TRUNC (T1.NBRJOBS_PERS_CHG_DATE) <= to_date(EffDate, 'MM/dd/yyyy')
       AND (   (T1.NBRJOBS_ANN_SALARY <= SALARY AND PICT_CODE = 'MN')
            OR (T1.NBRJOBS_REG_RATE <= SALARY AND PICT_CODE = 'SM'))
       AND T1.NBRJOBS_EFFECTIVE_DATE =
              (SELECT MAX (T11.NBRJOBS_EFFECTIVE_DATE)
                 FROM NBRJOBS T11
                WHERE     T1.NBRJOBS_PIDM = T11.NBRJOBS_PIDM
                      AND T1.NBRJOBS_POSN = T11.NBRJOBS_POSN
                      AND T1.NBRJOBS_SUFF = T11.NBRJOBS_SUFF
                      AND TRUNC (T11.NBRJOBS_EFFECTIVE_DATE) <=
                            to_date(EffDate, 'MM/dd/yyyy'));

  RETURN c_6_months_sal;

END f_get_6_months_salary;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_sal_increase
-- PRODUCT....: HR/Reclassification
-- USAGE......: get salary increased in the last 6 months
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return salary increased in the last 6 months
--------------------------------------------------------------------------------------------

FUNCTION f_get_sal_increase (
        PIDM VARCHAR2, 
        POSN varchar2, 
        SUFF varchar2, 
        PICT_CODE varchar2,
        OLD_PAY varchar2,        
        PAY_INCREASE_DATE varchar2)        
RETURN number
AS
   annual_salary number default 0;   

BEGIN

SELECT T1.NBRJOBS_ANN_SALARY
  INTO annual_salary
  FROM NBRJOBS T1
 WHERE     T1.NBRJOBS_PIDM = PIDM
       AND T1.NBRJOBS_POSN = POSN
       AND T1.NBRJOBS_SUFF = SUFF
       AND (   (T1.NBRJOBS_ANN_SALARY < OLD_PAY AND PICT_CODE = 'MN')
            OR (T1.NBRJOBS_REG_RATE < OLD_PAY AND PICT_CODE = 'SM'))
       AND T1.NBRJOBS_PERS_CHG_DATE =
              (SELECT MAX (T11.NBRJOBS_PERS_CHG_DATE)
                 FROM NBRJOBS T11
                WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                      AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                      AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                      AND T11.NBRJOBS_PERS_CHG_DATE <
                             to_date(PAY_INCREASE_DATE, 'MM/dd/yyyy'));


RETURN annual_salary;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       return annual_salary;
     WHEN OTHERS THEN
       RAISE;
END f_get_sal_increase;


--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_hr_incumbents
-- PRODUCT....: HR/New Position
-- USAGE......: get hr incumbents
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will return  hr incumbents  based on chart and pclass
--------------------------------------------------------------------------------------------

FUNCTION f_get_hr_incumbents (chart varchar2, pclass varchar2, orgn varchar2)
   RETURN SYS_REFCURSOR
AS
   c_incumbents SYS_REFCURSOR;

BEGIN

IF chart = 'H' THEN

OPEN c_incumbents FOR

  SELECT TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME AS EMPLOYEE,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID AS EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7 AS DEPARTMENT,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY AS SALARY,
         ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE, 2) AS HOURLY_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END
            AS INTO_RANGE,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                         TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
            AS TIME_ON_THE_JOB                
    FROM (SELECT "CURRENT_NBAJOBS".*,
                 OH.ORGANIZATION_DESC_7,
                    EMPLOYEE.SPRIDEN_LAST_NAME
                 || ', '
                 || EMPLOYEE.SPRIDEN_FIRST_NAME
                    AS EMPLOYEE_NAME,
                 EMPLOYEE.SPRIDEN_ID AS EMPLOYEE_ID,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_LOW (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS LOW_AMOUNT,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_MAX (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS MAX_AMOUNT,
                 T1.NBRJOBS_EFFECTIVE_DATE AS BEGIN_DATE
            FROM ((((((NBRJOBS CURRENT_NBAJOBS
                      INNER JOIN SPRIDEN EMPLOYEE
                         ON EMPLOYEE.SPRIDEN_PIDM =
                               CURRENT_NBAJOBS.NBRJOBS_PIDM)
                     INNER JOIN NBBPOSN POSN
                        ON POSN.NBBPOSN_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN)
                    INNER JOIN NBRJOBS T1
                       ON T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                   INNER JOIN NBRBJOB BR
                      ON BR.NBRBJOB_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                  INNER JOIN TTUFISCAL.FWVORGN OH
                     ON     OH.ORGANIZATION_LEVEL_7 =
                               CURRENT_NBAJOBS.NBRJOBS_ORGN_CODE_TS
                        AND OH.CHART_OF_ACCOUNTS =
                               CURRENT_NBAJOBS.NBRJOBS_COAS_CODE_TS)
		  INNER JOIN TTUFISCAL.FWVDPT7_MV CM
                      ON CM.L7_ORGN_CODE = CURRENT_NBAJOBS.NBRJOBS_ORGN_CODE_TS
                      AND CM.COAS_CODE = CURRENT_NBAJOBS.NBRJOBS_COAS_CODE_TS)   
           WHERE     SPRIDEN_CHANGE_IND IS NULL
                 AND POSN.NBBPOSN_COAS_CODE = chart
                 AND POSN.NBBPOSN_PCLS_CODE = pclass
 		 AND CM.L5_CAM_CODE in (select L5_CAM_CODE from TTUFISCAL.FWVDPT7_MV where L7_ORGN_CODE = orgn)
                 AND BR.NBRBJOB_CONTRACT_TYPE = 'P'
                 AND BR.NBRBJOB_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND BR.NBRBJOB_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND POSN.NBBPOSN_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_STATUS = 'A'
                 AND OH.ORGANIZATION_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM =
                                       CURRENT_NBAJOBS.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN =
                                       CURRENT_NBAJOBS.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF =
                                       CURRENT_NBAJOBS.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM
                 AND T1.NBRJOBS_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND T1.NBRJOBS_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND T1.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MIN (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND (   POSN.NBBPOSN_END_DATE IS NULL
                      OR POSN.NBBPOSN_END_DATE > SYSDATE)) TTB_CURRENT_NBAJOBS
GROUP BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY,
         TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (
                            TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                            TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
ORDER BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME ASC;

ELSE

OPEN c_incumbents FOR

SELECT TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME AS EMPLOYEE,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID AS EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7 AS DEPARTMENT,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY AS SALARY,
         ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE, 2) AS HOURLY_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END
            AS INTO_RANGE,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                         TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
            AS TIME_ON_THE_JOB
    FROM (SELECT "CURRENT_NBAJOBS".*,
                 OH.ORGANIZATION_DESC_7,
                    EMPLOYEE.SPRIDEN_LAST_NAME
                 || ', '
                 || EMPLOYEE.SPRIDEN_FIRST_NAME
                    AS EMPLOYEE_NAME,
                 EMPLOYEE.SPRIDEN_ID AS EMPLOYEE_ID,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_LOW (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS LOW_AMOUNT,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_MAX (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS MAX_AMOUNT,
                 T1.NBRJOBS_EFFECTIVE_DATE AS BEGIN_DATE
            FROM (((((NBRJOBS CURRENT_NBAJOBS
                      INNER JOIN SPRIDEN EMPLOYEE
                         ON EMPLOYEE.SPRIDEN_PIDM =
                               CURRENT_NBAJOBS.NBRJOBS_PIDM)
                     INNER JOIN NBBPOSN POSN
                        ON POSN.NBBPOSN_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN)
                    INNER JOIN NBRJOBS T1
                       ON T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                   INNER JOIN NBRBJOB BR
                      ON BR.NBRBJOB_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                  INNER JOIN TTUFISCAL.FWVORGN OH
                     ON     OH.ORGANIZATION_LEVEL_7 =
                               CURRENT_NBAJOBS.NBRJOBS_ORGN_CODE_TS
                        AND OH.CHART_OF_ACCOUNTS =
                               CURRENT_NBAJOBS.NBRJOBS_COAS_CODE_TS)
           WHERE     SPRIDEN_CHANGE_IND IS NULL
                 AND POSN.NBBPOSN_COAS_CODE = chart
                 AND POSN.NBBPOSN_PCLS_CODE = pclass
                 AND BR.NBRBJOB_CONTRACT_TYPE = 'P'
                 AND BR.NBRBJOB_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND BR.NBRBJOB_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND POSN.NBBPOSN_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_STATUS = 'A'
                 AND OH.ORGANIZATION_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM =
                                       CURRENT_NBAJOBS.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN =
                                       CURRENT_NBAJOBS.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF =
                                       CURRENT_NBAJOBS.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM
                 AND T1.NBRJOBS_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND T1.NBRJOBS_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND T1.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MIN (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND (   POSN.NBBPOSN_END_DATE IS NULL
                      OR POSN.NBBPOSN_END_DATE > SYSDATE)) TTB_CURRENT_NBAJOBS
GROUP BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY,
         TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (
                            TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                            TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
ORDER BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME ASC;

END IF;

RETURN c_incumbents ;

EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      RETURN c_incumbents;
   WHEN OTHERS
   THEN
      RAISE;

END f_get_hr_incumbents;



--------------------------------------------------------------------------------------------
-- OBJECT NAME: f_get_hr_incumbents_counts
-- PRODUCT....: HR/New Position
-- USAGE......: get hr incumbents counts
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Chai Alugolu
--
-- DESCRIPTION:
--
-- This function will use f_get_hr_incumbents function and return the 
-- hr incumbents counts  based on chart and pclass
--------------------------------------------------------------------------------------------

FUNCTION f_get_hr_incumbents_counts (chart varchar2, pclass varchar2, orgn varchar2)
   RETURN SYS_REFCURSOR
AS
   c_counts SYS_REFCURSOR;

BEGIN

IF chart = 'H' THEN

OPEN c_counts FOR  

SELECT COUNT (*) AS HEAD_COUNT,
       ROUND (MIN (SALARY), 2) AS MINIMUM_SALARY,
       ROUND (MIN (HOURLY_RATE), 2) AS MINIMUM_HOURLY,
       ROUND (MIN (INTO_RANGE), 2) AS MINIMUM_RANGE,
       FLOOR (MIN (TIME_ON_THE_JOB)) AS MINIMUM_TIME,
       ROUND (AVG (SALARY), 2) AS AVERAGE_SALARY,
       ROUND (AVG (HOURLY_RATE), 2) AS AVERAGE_HOURLY,
       ROUND (AVG (INTO_RANGE), 2) AS AVERAGE_RANGE,
       FLOOR (AVG (TIME_ON_THE_JOB)) AS AVERAGE_TIME,
       ROUND (MAX (SALARY), 2) AS MAXIMUM_SALARY,
       ROUND (MAX (HOURLY_RATE), 2) AS MAXIMUM_HOURLY,
       ROUND (MAX (INTO_RANGE), 2) AS MAXIMUM_RANGE,
       FLOOR (MAX (TIME_ON_THE_JOB)) AS MAXIMUM_TIME
  FROM (    SELECT TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME AS EMPLOYEE,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID AS EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7 AS DEPARTMENT,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY AS SALARY,
         ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE, 2) AS HOURLY_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END
            AS INTO_RANGE,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                         TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
            AS TIME_ON_THE_JOB                
    FROM (SELECT "CURRENT_NBAJOBS".*,
                 OH.ORGANIZATION_DESC_7,
                    EMPLOYEE.SPRIDEN_LAST_NAME
                 || ', '
                 || EMPLOYEE.SPRIDEN_FIRST_NAME
                    AS EMPLOYEE_NAME,
                 EMPLOYEE.SPRIDEN_ID AS EMPLOYEE_ID,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_LOW (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS LOW_AMOUNT,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_MAX (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS MAX_AMOUNT,
                 T1.NBRJOBS_EFFECTIVE_DATE AS BEGIN_DATE
            FROM ((((((NBRJOBS CURRENT_NBAJOBS
                      INNER JOIN SPRIDEN EMPLOYEE
                         ON EMPLOYEE.SPRIDEN_PIDM =
                               CURRENT_NBAJOBS.NBRJOBS_PIDM)
                     INNER JOIN NBBPOSN POSN
                        ON POSN.NBBPOSN_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN)
                    INNER JOIN NBRJOBS T1
                       ON T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                   INNER JOIN NBRBJOB BR
                      ON BR.NBRBJOB_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                  INNER JOIN TTUFISCAL.FWVORGN OH
                     ON     OH.ORGANIZATION_LEVEL_7 =
                               CURRENT_NBAJOBS.NBRJOBS_ORGN_CODE_TS
                        AND OH.CHART_OF_ACCOUNTS =
                               CURRENT_NBAJOBS.NBRJOBS_COAS_CODE_TS)
		 INNER JOIN TTUFISCAL.FWVDPT7_MV CM
                      ON CM.L7_ORGN_CODE = CURRENT_NBAJOBS.NBRJOBS_ORGN_CODE_TS
                      AND CM.COAS_CODE = CURRENT_NBAJOBS.NBRJOBS_COAS_CODE_TS) 
           WHERE     SPRIDEN_CHANGE_IND IS NULL
                 AND POSN.NBBPOSN_COAS_CODE = chart
                 AND POSN.NBBPOSN_PCLS_CODE = pclass
		 AND CM.L5_CAM_CODE in (select L5_CAM_CODE from TTUFISCAL.FWVDPT7_MV where L7_ORGN_CODE = orgn)
                 AND BR.NBRBJOB_CONTRACT_TYPE = 'P'
                 AND BR.NBRBJOB_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND BR.NBRBJOB_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND POSN.NBBPOSN_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_STATUS = 'A'
                 AND OH.ORGANIZATION_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM =
                                       CURRENT_NBAJOBS.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN =
                                       CURRENT_NBAJOBS.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF =
                                       CURRENT_NBAJOBS.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM
                 AND T1.NBRJOBS_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND T1.NBRJOBS_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND T1.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MIN (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND (   POSN.NBBPOSN_END_DATE IS NULL
                      OR POSN.NBBPOSN_END_DATE > SYSDATE)) TTB_CURRENT_NBAJOBS
GROUP BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY,
         TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (
                            TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                            TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
ORDER BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME ASC);

ELSE

OPEN c_counts FOR

SELECT COUNT (*) AS HEAD_COUNT,
       ROUND (MIN (SALARY), 2) AS MINIMUM_SALARY,
       ROUND (MIN (HOURLY_RATE), 2) AS MINIMUM_HOURLY,
       ROUND (MIN (INTO_RANGE), 2) AS MINIMUM_RANGE,
       FLOOR (MIN (TIME_ON_THE_JOB)) AS MINIMUM_TIME,
       ROUND (AVG (SALARY), 2) AS AVERAGE_SALARY,
       ROUND (AVG (HOURLY_RATE), 2) AS AVERAGE_HOURLY,
       ROUND (AVG (INTO_RANGE), 2) AS AVERAGE_RANGE,
       FLOOR (AVG (TIME_ON_THE_JOB)) AS AVERAGE_TIME,
       ROUND (MAX (SALARY), 2) AS MAXIMUM_SALARY,
       ROUND (MAX (HOURLY_RATE), 2) AS MAXIMUM_HOURLY,
       ROUND (MAX (INTO_RANGE), 2) AS MAXIMUM_RANGE,
       FLOOR (MAX (TIME_ON_THE_JOB)) AS MAXIMUM_TIME
  FROM (    SELECT TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME AS EMPLOYEE,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID AS EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7 AS DEPARTMENT,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY AS SALARY,
         ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE, 2) AS HOURLY_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END
            AS INTO_RANGE,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                         TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
            AS TIME_ON_THE_JOB                
    FROM (SELECT "CURRENT_NBAJOBS".*,
                 OH.ORGANIZATION_DESC_7,
                    EMPLOYEE.SPRIDEN_LAST_NAME
                 || ', '
                 || EMPLOYEE.SPRIDEN_FIRST_NAME
                    AS EMPLOYEE_NAME,
                 EMPLOYEE.SPRIDEN_ID AS EMPLOYEE_ID,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_LOW (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS LOW_AMOUNT,
                 TTUFISCAL.PWKMISC.F_GET_PAY_RANGE_MAX (POSN.NBBPOSN_PCLS_CODE,
                                                        POSN.NBBPOSN_COAS_CODE)
                    AS MAX_AMOUNT,
                 T1.NBRJOBS_EFFECTIVE_DATE AS BEGIN_DATE
            FROM (((((NBRJOBS CURRENT_NBAJOBS
                      INNER JOIN SPRIDEN EMPLOYEE
                         ON EMPLOYEE.SPRIDEN_PIDM =
                               CURRENT_NBAJOBS.NBRJOBS_PIDM)
                     INNER JOIN NBBPOSN POSN
                        ON POSN.NBBPOSN_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN)
                    INNER JOIN NBRJOBS T1
                       ON T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                   INNER JOIN NBRBJOB BR
                      ON BR.NBRBJOB_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM)
                  INNER JOIN TTUFISCAL.FWVORGN OH
                     ON     OH.ORGANIZATION_LEVEL_7 =
                               CURRENT_NBAJOBS.NBRJOBS_ORGN_CODE_TS
                        AND OH.CHART_OF_ACCOUNTS =
                               CURRENT_NBAJOBS.NBRJOBS_COAS_CODE_TS)
           WHERE     SPRIDEN_CHANGE_IND IS NULL
                 AND POSN.NBBPOSN_COAS_CODE = chart
                 AND POSN.NBBPOSN_PCLS_CODE = pclass
                 AND BR.NBRBJOB_CONTRACT_TYPE = 'P'
                 AND BR.NBRBJOB_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND BR.NBRBJOB_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND POSN.NBBPOSN_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_STATUS = 'A'
                 AND OH.ORGANIZATION_STATUS = 'A'
                 AND CURRENT_NBAJOBS.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MAX (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM =
                                       CURRENT_NBAJOBS.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN =
                                       CURRENT_NBAJOBS.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF =
                                       CURRENT_NBAJOBS.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND T1.NBRJOBS_PIDM = CURRENT_NBAJOBS.NBRJOBS_PIDM
                 AND T1.NBRJOBS_POSN = CURRENT_NBAJOBS.NBRJOBS_POSN
                 AND T1.NBRJOBS_SUFF = CURRENT_NBAJOBS.NBRJOBS_SUFF
                 AND T1.NBRJOBS_EFFECTIVE_DATE =
                        (SELECT MIN (NBRJOBS_EFFECTIVE_DATE)
                           FROM NBRJOBS T11
                          WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                                AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)
                 AND (   POSN.NBBPOSN_END_DATE IS NULL
                      OR POSN.NBBPOSN_END_DATE > SYSDATE)) TTB_CURRENT_NBAJOBS
GROUP BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME,
         TTB_CURRENT_NBAJOBS.EMPLOYEE_ID,
         TTB_CURRENT_NBAJOBS.ORGANIZATION_DESC_7,
         TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY,
         TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE,
         CASE TTB_CURRENT_NBAJOBS.NBRJOBS_PICT_CODE
            WHEN 'SM'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_REG_RATE
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            WHEN 'MN'
            THEN
               ROUND (
                    (  (  TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT)
                     / (  TTB_CURRENT_NBAJOBS.MAX_AMOUNT
                        - TTB_CURRENT_NBAJOBS.LOW_AMOUNT))
                  * 100,
                  2)
            ELSE
               ROUND (TTB_CURRENT_NBAJOBS.NBRJOBS_ANN_SALARY * 100, 2)
         END,
         CASE
            WHEN SUBSTR (
                    TRUNC (
                         MONTHS_BETWEEN (
                            TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                            TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                       / 12,
                       2),
                    -2,
                    2) >= 96
            THEN
               ROUND (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
            ELSE
               TRUNC (
                    MONTHS_BETWEEN (TO_DATE ('07/10/2018', 'MM/dd/yyyy'),
                                    TTB_CURRENT_NBAJOBS.BEGIN_DATE)
                  / 12)
         END
ORDER BY TTB_CURRENT_NBAJOBS.EMPLOYEE_NAME ASC);

END IF;

RETURN c_counts;

EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      RETURN c_counts;
   WHEN OTHERS
   THEN
      RAISE;

END f_get_hr_incumbents_counts;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: getCalcEffDate
-- PRODUCT....: HR/New Position/ReClass
-- USAGE......: get calculated effective date
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarasan R
--
-- DESCRIPTION:
--
-- This function will use the Ptrecls_Pict_Code and NC_PASS_TRANS_B.APPROVAL_DATE and NC_PASS_TRANS_B.POSN_EFFECTIVE_DATE
-- and return the calculated Effective Date
--------------------------------------------------------------------------------------------

FUNCTION getCalcEffDate(p_ECLS_PICT_CODE VARCHAR2, p_APPROVAL_DATE DATE, p_POSN_EFFECTIVE_DATE date) RETURN date 
IS 
v_calc_eff_date           date;
v_cnt_payroll_date        NUMBER;
--v_ptrcaln_start_date PTRCALN.PTRCALN_START_DATE%type;
v_payroll_start_date      ttufiscal.pwbpyst.PWBPYST_START_DATE%type;

        BEGIN
          
          IF(p_ECLS_PICT_CODE = 'NS') THEN
              v_calc_eff_date :=   p_POSN_EFFECTIVE_DATE;
              dbms_output.put_line(chr(10)||'NS'||chr(10)||
            'p_ECLS_PICT_CODE: '||p_ECLS_PICT_CODE||chr(10)--||
            --'p_APPROVAL_DATE: '||p_APPROVAL_DATE||chr(10)
            ); 
          ELSE
          
--            select PTRCALN_START_DATE
--            into v_ptrcaln_start_date
--            from PTRCALN p1 where
--            PTRCALN_PICT_CODE = p_ECLS_PICT_CODE and
--            PTRCALN_START_DATE =
--            (select min(p2.PTRCALN_START_DATE) from PTRCALN p2
--              where
--              p2.PTRCALN_START_DATE > p_POSN_EFFECTIVE_DATE --p_APPROVAL_DATE
--              and p2.ptrcaln_pict_code = p1.ptrcaln_pict_code);


            select count(*) into v_cnt_payroll_date
            from ttufiscal.pwbpyst
            where PWBPYST_PICT_CODE    = p_ECLS_PICT_CODE
            and PWBPYST_COMPLETE       = 'N'
            and PWBPYST_START_DATE <= p_APPROVAL_DATE;
            
            IF(v_cnt_payroll_date > 0) THEN
            
                select max(PWBPYST_START_DATE) 
                into v_payroll_start_date 
                from ttufiscal.pwbpyst
                where PWBPYST_PICT_CODE    = p_ECLS_PICT_CODE
                and PWBPYST_COMPLETE       = 'N'
                and PWBPYST_START_DATE    <= p_APPROVAL_DATE; --budget approval date

            
            ELSE
                select min(PWBPYST_START_DATE)
                into v_payroll_start_date
                from ttufiscal.pwbpyst
                where PWBPYST_PICT_CODE    = p_ECLS_PICT_CODE
                and PWBPYST_COMPLETE       = 'N'
                and PWBPYST_START_DATE    >= p_APPROVAL_DATE;
            
            END IF;
  
            select GREATEST(v_payroll_start_date,p_POSN_EFFECTIVE_DATE)
            into  v_calc_eff_date
            from dual;
         END IF;   
          
          dbms_output.put_line(chr(10)||
          'p_ECLS_PICT_CODE: '||p_ECLS_PICT_CODE||chr(10)||
          'p_APPROVAL_DATE: '||p_APPROVAL_DATE||chr(10)||
          'p_POSN_EFFECTIVE_DATE: '||p_POSN_EFFECTIVE_DATE||chr(10)||
         -- 'v_ptrcaln_start_date: '||v_ptrcaln_start_date||chr(10)||
          'v_calc_eff_date: '||v_calc_eff_date||chr(10)||
          chr(10)
          ); 
          
        RETURN v_calc_eff_date;
        END getCalcEffDate;
--------------------------------------------------------------------------------------------
-- OBJECT NAME: getEpafTransNo
-- PRODUCT....: HR/New Position/ReClass/Salary Review
-- USAGE......: get Transaction Number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarasan R
--
-- DESCRIPTION:
--
-- This function will return the next transaction number
--------------------------------------------------------------------------------------------        
FUNCTION getEpafTransNo RETURN number 
IS v_transaction_no number;

        BEGIN
            select (BANINST1.nokepcr.f_get_next_trans_no) into v_transaction_no from dual;
          
          dbms_output.put_line(chr(10)||'v_transaction_no: '||v_transaction_no||chr(10)); 
          
        RETURN v_transaction_no;
        END getEpafTransNo;     
--------------------------------------------------------------------------------------------
-- OBJECT NAME: fstringConcat
-- PRODUCT....: HR/New Position/ReClass/Salary Review
-- USAGE......: get Transaction Number
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarasan R
--
-- DESCRIPTION:
--
-- This function will concatenate two comment string with each other. The second string will begin in the 
-- next line, if the length exceeds 2000 characters the last three characters will be replaced by "..." 
--------------------------------------------------------------------------------------------          
FUNCTION fstringConcat(p_str_1 varchar2, p_str_2 varchar2) RETURN varchar2
IS v_string_ret               varchar2(2000);
   v_diff                     number;

        BEGIN
           
            dbms_output.put_line(chr(10)||'p_str_1: '||LENGTH(p_str_1)||
                                      chr(10)||'p_str_2: '||LENGTH(p_str_2));
                                      
            if (LENGTH(p_str_1) > 1996) then
               v_string_ret := SUBSTR(p_str_1,0,1996)||'...';
               
               elsif((LENGTH(p_str_1) < 1996) and (LENGTH(p_str_2) > 1996 ))then
               v_diff :=   1999 - LENGTH(p_str_1) - 3;
               v_string_ret := p_str_1||chr(10)||SUBSTR(p_str_2,0,v_diff)||'...';
               
               elsif((p_str_1 is null) and (p_str_2 is null)) then
               v_string_ret := null;
               
               elsif((p_str_1 is null) and (p_str_2 is NOT null)) then
               v_string_ret := p_str_2;
               
               elsif((p_str_1 is not null) and (p_str_2 is null)) then
               v_string_ret := p_str_1;
               
               elsif( (LENGTH(p_str_1) + LENGTH(p_str_2)) > 1996 ) then
               v_diff :=   1999 - LENGTH(p_str_1) - 3;
               
               v_string_ret := p_str_1||chr(10)||SUBSTR(p_str_2,0,v_diff)||'...';
--               
--               dbms_output.put_line(chr(10)||'v_diff: '||v_diff||
--                                      chr(10)||'p_str_2: '||SUBSTR(p_str_2,0,v_diff));
               
               else
               v_string_ret := p_str_1||chr(10)||p_str_2;
               
            end if;  
            
            dbms_output.put_line(chr(10)||
            --'v_string_ret: '||v_string_ret||
                                      chr(10)||'LENGTH(v_string_ret): '||LENGTH(v_string_ret));
                                                               
        RETURN v_string_ret;
        END fstringConcat; 
--------------------------------------------------------------------------------------------
-- OBJECT NAME: getElPasoRCFlag
-- PRODUCT....: HR/New Position/ReClass/Salary Review
-- USAGE......: get El Paso Reclassification Flag
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarasan R
--
-- DESCRIPTION:
--
-- This function will indicate if a transaction is a Filled Reclass El Paso (Coas Code E) Transaction
--------------------------------------------------------------------------------------------            
        
FUNCTION getElPasoRCFlag(p_trans_no IN varchar2, p_coas_code IN varchar2,p_pidm IN VARCHAR2,
p_fut_vacant  IN varchar2, p_apr_date in date, p_bnr_upload  IN varchar2, p_calc_eff_date in date) RETURN varchar2
IS
       
v_ElPaso_flag  varchar2(1);
    BEGIN 
    --flag N  indicates that this is NOT a El Paso Filled reclass where effective date is met
    v_ElPaso_flag   := 'N';

    dbms_output.put_line('p_trans_no: '||p_trans_no); 
    
    IF(  ( (substr(p_trans_no,1,2)) <> 'RC' ) AND ( (substr(p_trans_no,1,2)) <> 'SR' ) ) THEN
        v_ElPaso_flag   := 'N';
        dbms_output.put_line('substr(p_trans_no,1,2)): '||substr(p_trans_no,1,2) );
    ELSIF(p_coas_code <> 'E') THEN 
        v_ElPaso_flag   := 'N';
        dbms_output.put_line('p_coas_code: '||p_coas_code);       
    ELSIF ( (p_pidm IS NULL) AND (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NULL) ) THEN
        v_ElPaso_flag   := 'N';
        dbms_output.put_line('p_pidm: '||p_pidm);    
    --ELSIF ( (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NULL) AND (sysdate >= trunc(p_calc_eff_date) )  )  THEN    
    ELSIF(  ( ( (substr(p_trans_no,1,2)) = 'SR' )   AND (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NULL) AND (p_fut_vacant is NULL))    
           OR ( ( (substr(p_trans_no,1,2)) = 'RC' ) AND (sysdate >= trunc(p_calc_eff_date) )  AND (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NULL) 
                 AND ( (p_fut_vacant = 'Y') OR (p_fut_vacant is NOT NULL) )
              ) 
          )  THEN        
         v_ElPaso_flag   := 'N';
        dbms_output.put_line('ELSIF: pass_trans_rec.EMPLOYEE_PIDM: '||p_pidm||chr(10)||
        'pass_trans_rec.FUTURE_VACANT: '||p_fut_vacant||chr(10)||
        'pass_trans_rec.APPROVAL_DATE: '||p_apr_date||chr(10)||
        'pass_trans_rec.BNR_UPLOAD: '   ||p_bnr_upload||chr(10)||
        'pass_trans_rec.CALC_EFF_DATE: '||p_calc_eff_date
         );
        v_ElPaso_flag   := 'N';
    
    ELSE 
        dbms_output.put_line('ELSE: pass_trans_rec.EMPLOYEE_PIDM: '||p_pidm||chr(10)||
        'pass_trans_rec.FUTURE_VACANT: '||p_fut_vacant||chr(10)||
        'pass_trans_rec.APPROVAL_DATE: '||p_apr_date||chr(10)||
        'pass_trans_rec.BNR_UPLOAD: '   ||p_bnr_upload||chr(10)||
        'pass_trans_rec.CALC_EFF_DATE: '||p_calc_eff_date
         );
                
        v_ElPaso_flag   := 'Y';
        
    END IF;
    
    RETURN v_ElPaso_flag;
    END getElPasoRCFlag;  

--------------------------------------------------------------------------------------------
-- OBJECT NAME: getElPasoRCFlag
-- PRODUCT....: HR/New Position/ReClass/Salary Review
-- USAGE......: get El Paso Reclassification Flag
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarasan R
--
-- DESCRIPTION:
--
-- This function will indicate if a transaction is a Filled Reclass El Paso (Coas Code E) Transaction       
--------------------------------------------------------------------------------------------            
        
FUNCTION getElPasoEPAFFlag(p_trans_no IN varchar2, p_coas_code IN varchar2,p_pidm IN VARCHAR2,
p_fut_vacant  IN varchar2, p_apr_date in date, p_bnr_upload  IN varchar2, p_calc_eff_date in date) RETURN varchar2
IS
       
v_ElPaso_flag  varchar2(1);
    BEGIN 
    --flag N  indicates that this is NOT a El Paso Filled reclass where effective date is met
    v_ElPaso_flag   := 'N';

    
    
    IF(  ( (substr(p_trans_no,1,2)) <> 'RC' ) AND ( (substr(p_trans_no,1,2)) <> 'SR' ) ) THEN
        v_ElPaso_flag   := 'N';
        dbms_output.put_line('substr(p_trans_no,1,2)): '||substr(p_trans_no,1,2) );
    ELSIF(p_coas_code <> 'E') THEN 
        v_ElPaso_flag   := 'N';
        dbms_output.put_line('p_coas_code: '||p_coas_code);
    /*ELSIF(
            (p_pidm IS NOT NULL) AND (p_fut_vacant   <> 'Y') AND
            
            (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NOT NULL) AND
            
            (sysdate >= p_calc_eff_date )
    ) THEN*/
    ELSIF (p_pidm IS NULL) THEN
        v_ElPaso_flag   := 'N';
        dbms_output.put_line('p_pidm: '||p_pidm);    

    ELSIF(  ( ( (substr(p_trans_no,1,2)) = 'SR' )   AND (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NOT NULL)  AND (p_fut_vacant is NULL) )    
             OR ( ( (substr(p_trans_no,1,2)) = 'RC' ) AND (sysdate >= trunc(p_calc_eff_date) )  AND (p_apr_date IS NOT NULL) AND (p_bnr_upload IS NOT NULL) 
             AND ( (p_fut_vacant = 'Y') OR (p_fut_vacant is NOT NULL) )  )
          )  THEN         
         v_ElPaso_flag   := 'N';          
        dbms_output.put_line('ELSIF: pass_trans_rec.EMPLOYEE_PIDM: '||p_pidm||chr(10)||
        'pass_trans_rec.FUTURE_VACANT: '||p_fut_vacant||chr(10)||
        'pass_trans_rec.APPROVAL_DATE: '||p_apr_date||chr(10)||
        'pass_trans_rec.BNR_UPLOAD: '   ||p_bnr_upload||chr(10)||
        'pass_trans_rec.CALC_EFF_DATE: '||p_calc_eff_date
         );
        v_ElPaso_flag   := 'N';
    
    ELSE 
        dbms_output.put_line('ELSE: pass_trans_rec.EMPLOYEE_PIDM: '||p_pidm||chr(10)||
        'pass_trans_rec.FUTURE_VACANT: '||p_fut_vacant||chr(10)||
        'pass_trans_rec.APPROVAL_DATE: '||p_apr_date||chr(10)||
        'pass_trans_rec.BNR_UPLOAD: '   ||p_bnr_upload||chr(10)||
        'pass_trans_rec.CALC_EFF_DATE: '||p_calc_eff_date
         );
                
        v_ElPaso_flag   := 'Y';
        
    END IF;
    
    RETURN v_ElPaso_flag;
    END getElPasoEPAFFlag;                          
--------------------------------------------------------------------------------------------
-- OBJECT NAME: p_np_banner_upd
-- PRODUCT....: HR
-- USAGE......: Update Banner tables and produce a report for the PASS Application  based
--              New Position Transaction
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--  This procedure will insert a line into each one of the below mentioned tables
-- 1) One line in NBBPOSN for the POSITION Number 
-- 2) One Line for each occurance of the Active Fiscal Year under NC_PASS_FISCYEAR_C Table in NBRPTOT
--     based on the Position Number
-- 3) One Line for each occurance of the Active Fiscal Year in NC_PASS_FISCYEAR_C Table in NBRPLBD
--     based on the Position Number
--------------------------------------------------------------------------------------------
PROCEDURE p_np_banner_upd(p_trans_no IN varchar2,  u_id IN  varchar2, rtn_flag OUT varchar2) IS
wfile_handle                                                        utl_file.file_type;
v_one_up                                                            integer;
v_file                                                              varchar2 (300);
v_wstring                                                           varchar2 (6000);
v_eprint_user                                                       varchar2(90);
v_date                                                              date;
trans_b_rec                                                         TT_HR_PASS.NC_PASS_TRANS_B%ROWTYPE;
transfunding_rec                                                    TT_HR_PASS.NC_PASS_TRANSFUNDING_R%ROWTYPE;
ntrpcls_rec                                                         NTRPCLS%ROWTYPE;
ptrecls_rec                                                         PTRECLS%ROWTYPE;
v_nbbposn_posn                                                      NBBPOSN.NBBPOSN_POSN%TYPE;
v_nbbposn_posn_bnr                                                  NBBPOSN.NBBPOSN_POSN%TYPE;
v_nbbposn_posn_no                                                   NUMBER;
v_nbbposn_comment                                                   NBBPOSN.NBBPOSN_COMMENT%TYPE;
v_nbrptot_budg_basis                                                NBRPTOT.NBRPTOT_BUDG_BASIS%TYPE;
v_nbrptot_ann_basis                                                 NBRPTOT.NBRPTOT_ANN_BASIS%TYPE;
v_nbrptot_base_units                                                NBRPTOT.NBRPTOT_BASE_UNITS%TYPE;
v_nbrptot_appt_pct                                                  NBRPTOT.NBRPTOT_APPT_PCT%TYPE;
v_pay_num                                                           NUMBER;
v_ptrcaln_start_date                                                PTRCALN.PTRCALN_START_DATE%TYPE;
v_eff_date                                                          NBRPTOT.NBRPTOT_EFFECTIVE_DATE%TYPE;
v_nbbposn_auth_number                                               NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE;
v_nbbposn_begin_date                                                NBBPOSN.NBBPOSN_BEGIN_DATE%TYPE; --HPSS-1784
v_nbbposn_sgrp_code                                                 NBBPOSN.NBBPOSN_SGRP_CODE%TYPE; --HPSS-1763
v_extract_date                                                      varchar2(20);      --HPSS-1693
v_extract_year                                                      varchar2(20);      --HPSS-1693
v_create_year                                                       number;

type r_FISC_YEAR                       IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.FISC_YEAR%TYPE;
type r_BUDGET_STATUS                   IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_STATUS%TYPE;
type r_BUDGET_ID                       IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_ID%TYPE;
type r_BUDGET_PHASE                    IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_PHASE%TYPE;

type r_PASS_POSN_NBR                   IS TABLE OF     TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE;
type r_PASS_COAS_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE;
type r_PASS_FUND_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_FUND_CODE%TYPE;
type r_PASS_ORGN_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_ORGN_CODE%TYPE;
type r_PASS_ACCT_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_ACCT_CODE%TYPE;

type r_PASS_POSN_PROG_CODE             IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_PROG_CODE%TYPE;
type r_PASS_POSN_CURR_ACCT_PERC        IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_CURRENT_ACCT_PERCENT%TYPE;

l_FISC_YEAR                       r_FISC_YEAR;
l_BUDGET_STATUS                   r_BUDGET_STATUS;
l_BUDGET_ID                       r_BUDGET_ID;
l_BUDGET_PHASE                    r_BUDGET_PHASE;

l_PASS_POSN_NBR                   r_PASS_POSN_NBR;
l_PASS_COAS_CODE                  r_PASS_COAS_CODE;
l_PASS_FUND_CODE                  r_PASS_FUND_CODE;
l_PASS_ACCT_CODE                  r_PASS_ACCT_CODE;
l_PASS_ORGN_CODE                  r_PASS_ORGN_CODE;

l_PASS_POSN_PROG_CODE             r_PASS_POSN_PROG_CODE ;                 
l_PASS_POSN_CURR_ACCT_PERC        r_PASS_POSN_CURR_ACCT_PERC ;

v_FISC_YEAR                       varchar2(4);

v_NBRPTOT_BUDGET                    NUMBER(11,2);
v_NBRPLBD_BUDGET                    NUMBER(11,2);
v_NBRPTOT_EFFECTIVE_DATE            NBRPTOT.NBRPTOT_EFFECTIVE_DATE%TYPE;
TYPE t_comment_table IS TABLE OF  VARCHAR2(2000)  -- Associative array type
INDEX BY VARCHAR2(4);
j                         varchar2(4);            -- scalar index variable

v_nbrptot_comment t_comment_table;
v_nbrplbd_comment t_comment_table;

v_holding_status varchar2(10);
v_trans_holding_status varchar2(2);
v_trans_holding_posn_nbr varchar2(6);
v_NTRPCLS_SGRP_CODE                                                 NTRPCLS.NTRPCLS_SGRP_CODE%TYPE;

CURSOR CURSOR_TRANS_B IS
     SELECT * FROM TT_HR_PASS.NC_PASS_TRANS_B
     WHERE TRANS_NO = p_trans_no
     AND BNR_UPLOAD IS NULL;

CURSOR CURSOR_NTRPCLS (p_pcls_code IN varchar2) IS
  SELECT * FROM NTRPCLS
  WHERE NTRPCLS_CODE = p_pcls_code;

CURSOR CURSOR_PTRECLS (p_ecls_code IN varchar2) IS
  SELECT * FROM PTRECLS
  WHERE PTRECLS_CODE = p_ecls_code;

CURSOR CURSOR_FISCYEAR (chart IN varchar2) IS
  select FISC_YEAR, BUDG_ID, BUDG_PHASE, BUDG_STATUS
  from tt_hr_pass.nc_pass_fiscyear_c
  where coas_code = chart
  and Status = 'A';

CURSOR CURSOR_TRANSFUNDING (trans_b_id IN number) IS
  select * from tt_hr_pass.nc_pass_transfunding_r
  WHERE NC_PASS_TRANS_B_ID = trans_b_id;
  
CURSOR CURSOR_NBRPLBD_FISCYEAR (p_chart IN varchar2, p_trans_no IN varchar2) IS 
select fisc.FISC_YEAR, fisc.BUDG_ID, fisc.BUDG_PHASE, fisc.BUDG_STATUS, trans_b.POSN_NBR, trans_b.POSN_COAS_CODE,  trans_f.POSN_FUND_CODE, trans_f.POSN_ORGN_CODE,
trans_f.POSN_ACCT_CODE,  trans_f.POSN_PROG_CODE,  trans_f.POSN_CURRENT_ACCT_PERCENT
from tt_hr_pass.nc_pass_fiscyear_c fisc, tt_hr_pass.nc_pass_trans_b trans_b, tt_hr_pass.nc_pass_transfunding_r trans_f 
where 
fisc.coas_code = p_chart AND  
fisc.Status = 'A'and 
trans_b.trans_no = p_trans_no  
and trans_f.NC_PASS_TRANS_B_ID =  trans_b.TRANS_ID;   

BEGIN

--1
savepoint s_pass_update_banner;
SELECT SYSDATE into v_date FROM DUAL;



v_file := 'p_pass_banner_update.xls';

wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');

v_wstring := 'TRANSACTION NUMBER'||chr(9)||p_trans_no;

DBMS_OUTPUT.PUT_LINE (v_wstring);

utl_file.put_line(wfile_handle,v_wstring);

v_wstring := 'DATE'||chr(9)||v_date;

DBMS_OUTPUT.PUT_LINE (v_wstring);

utl_file.put_line(wfile_handle,v_wstring);

OPEN CURSOR_TRANS_B;

   FETCH CURSOR_TRANS_B INTO trans_b_rec;

   DBMS_OUTPUT.PUT_LINE (' trans_b_rec.POSN_NBR: '||chr(9)||trans_b_rec.POSN_NBR);

CLOSE CURSOR_TRANS_B; 

v_nbbposn_posn    :=  trans_b_rec.POSN_NBR;

--Check if POSN_CODE  already exists in Banner Table
select count(*) into v_nbbposn_posn_no from  NBBPOSN
WHERE NBBPOSN_POSN =  v_nbbposn_posn;

if (v_nbbposn_posn_no > 0) then
v_nbbposn_posn_bnr := v_nbbposn_posn;
--If the POSN_CODE exists generate new POSN_CODE
  WHILE(v_nbbposn_posn =  v_nbbposn_posn_bnr) LOOP    
      DBMS_OUTPUT.PUT_LINE ('Generating new Posn Code');
      v_nbbposn_posn := TT_HR_PASS.NWKPASS.GetNextPosnCode(trans_b_rec.POSN_COAS_CODE, trans_b_rec.POSN_NBR);
      
      --Check if new position number also exists in banner
      select count(*) into v_nbbposn_posn_no from  NBBPOSN
      WHERE NBBPOSN_POSN =  v_nbbposn_posn;
        if (v_nbbposn_posn_no > 0) then
        v_nbbposn_posn_bnr := v_nbbposn_posn;
        end if;
  END LOOP;     
end if;

v_nbbposn_comment := 'Position inserted by PASS '||p_trans_no||' with Eff Date '||trans_b_rec.POSN_EFFECTIVE_DATE||' on '||v_date;

DBMS_OUTPUT.PUT_LINE (' v_nbbposn_comment: '||chr(9)||v_nbbposn_comment);

OPEN CURSOR_NTRPCLS(trans_b_rec.POSN_PCLS_CODE);

   FETCH CURSOR_NTRPCLS INTO ntrpcls_rec;

   DBMS_OUTPUT.PUT_LINE (' ntrpcls_rec.NTRPCLS_CODE: '||chr(9)||ntrpcls_rec.NTRPCLS_CODE);

CLOSE CURSOR_NTRPCLS;

OPEN CURSOR_PTRECLS(trans_b_rec.POSN_ECLS_CODE);

   FETCH CURSOR_PTRECLS INTO ptrecls_rec;

   DBMS_OUTPUT.PUT_LINE (' ptrecls_rec.PTRECLS_CODE: '||chr(9)||ptrecls_rec.PTRECLS_CODE);

CLOSE CURSOR_PTRECLS;

--v_nbbposn_auth_number  := 'PASS '||nvl(trans_b_rec.BO_APPROVER, '');
DBMS_OUTPUT.PUT_LINE (' trans_b_rec.BO_APPROVER: '||chr(9)||trans_b_rec.BO_APPROVER);
IF (trans_b_rec.BO_APPROVER = 'PASS') THEN
        v_nbbposn_auth_number   :=  'PASS';
ELSE
        v_nbbposn_auth_number   :=  'PASS '||nvl(trans_b_rec.BO_APPROVER, '');
END IF;

DBMS_OUTPUT.PUT_LINE (' v_nbbposn_auth_number: '||chr(9)||v_nbbposn_auth_number);

v_eff_date  :=  getCalcEffDate(ptrecls_rec.PTRECLS_PICT_CODE, v_date, trans_b_rec.POSN_EFFECTIVE_DATE);

select FISC_YEAR into  v_nbbposn_sgrp_code
from tt_hr_pass.nc_pass_fiscyear_c where BUDG_STATUS = 'A' and STATUS = 'A' and coas_code = trans_b_rec.POSN_COAS_CODE;   --HPSS-1763

v_nbbposn_sgrp_code := 'FY'||v_nbbposn_sgrp_code;  --HPSS-1763

v_nbbposn_begin_date := trunc(trans_b_rec.POSN_EFFECTIVE_DATE); --HPSS-1784


INSERT INTO NBBPOSN (
NBBPOSN_POSN, NBBPOSN_STATUS, NBBPOSN_TITLE, NBBPOSN_BEGIN_DATE, NBBPOSN_TYPE,

NBBPOSN_PCLS_CODE, NBBPOSN_ECLS_CODE, NBBPOSN_TABLE, NBBPOSN_GRADE,

NBBPOSN_APPT_PCT, NBBPOSN_ROLL_IND, NBBPOSN_ACTIVITY_DATE, NBBPOSN_PREMIUM_ROLL_IND,

NBBPOSN_CHANGE_DATE_TIME, NBBPOSN_EXEMPT_IND, NBBPOSN_ACCRUE_SENIORITY_IND, NBBPOSN_BUDGET_TYPE,

NBBPOSN_PLOC_CODE, NBBPOSN_END_DATE,

NBBPOSN_POSN_REPORTS, NBBPOSN_AUTH_NUMBER, NBBPOSN_STEP, NBBPOSN_CIPC_CODE,

NBBPOSN_COAS_CODE, NBBPOSN_SGRP_CODE, NBBPOSN_PGRP_CODE, NBBPOSN_WKSH_CODE,

NBBPOSN_PFOC_CODE, NBBPOSN_PNOC_CODE, NBBPOSN_DOTT_CODE, NBBPOSN_CALIF_TYPE,

NBBPOSN_JBLN_CODE, NBBPOSN_BARG_CODE, NBBPOSN_PROBATION_UNITS, NBBPOSN_COMMENT,

NBBPOSN_JOBP_CODE, NBBPOSN_BPRO_CODE, NBBPOSN_USER_ID, NBBPOSN_DATA_ORIGIN,

NBBPOSN_VPDI_CODE, NBBPOSN_ESOC_CODE, NBBPOSN_ECIP_CODE,NBBPOSN_GUID
)
Values (
v_nbbposn_posn, 'A', trans_b_rec.POSN_EXTENDED_TITLE, v_nbbposn_begin_date, trans_b_rec.POSN_SINGLE_POOLED,

trans_b_rec.POSN_PCLS_CODE, trans_b_rec.POSN_ECLS_CODE, ntrpcls_rec.NTRPCLS_TABLE, trans_b_rec.POSN_PAY_GRADE,

100, ptrecls_rec.PTRECLS_BUDGET_ROLL_IND, v_date, ptrecls_rec.PTRECLS_PREMIUM_ROLL_IND,

v_date, ntrpcls_rec.NTRPCLS_EXEMPT_IND, ntrpcls_rec.NTRPCLS_ACCRUE_SENIORITY_IND, 'P',

null, null,

null, v_nbbposn_auth_number, null, null,

trans_b_rec.POSN_COAS_CODE, v_nbbposn_sgrp_code, ntrpcls_rec.NTRPCLS_PGRP_CODE, null,

trans_b_rec.POSN_FOC_CODE, null, null, null,

null, null, null, v_nbbposn_comment,

null, null, 'TT_HR_PASS', null,

null, ntrpcls_rec.NTRPCLS_ESOC_CODE, ntrpcls_rec.NTRPCLS_ECIP_CODE,null
);

v_wstring := 'NBBPOSN_POSN'||chr(9)||'NBBPOSN_STATUS'||chr(9)||'NBBPOSN_TITLE'||chr(9)||'NBBPOSN_BEGIN_DATE'||chr(9)||'NBBPOSN_TYPE'||chr(9)||

'NBBPOSN_PCLS_CODE'||chr(9)||'NBBPOSN_ECLS_CODE'||chr(9)||'NBBPOSN_TABLE'||chr(9)||'NBBPOSN_GRADE'||chr(9)||

'NBBPOSN_APPT_PCT'||chr(9)||'NBBPOSN_ROLL_IND'||chr(9)||'NBBPOSN_ACTIVITY_DATE'||chr(9)||'NBBPOSN_PREMIUM_ROLL_IND'||chr(9)||

'NBBPOSN_CHANGE_DATE_TIME'||chr(9)||'NBBPOSN_EXEMPT_IND'||chr(9)||'NBBPOSN_ACCRUE_SENIORITY_IND'||chr(9)||'NBBPOSN_BUDGET_TYPE'||chr(9)||

'NBBPOSN_PLOC_CODE'||chr(9)||'NBBPOSN_END_DATE'||chr(9)||

'NBBPOSN_POSN_REPORTS'||chr(9)||'NBBPOSN_AUTH_NUMBER'||chr(9)||'NBBPOSN_STEP'||chr(9)||'NBBPOSN_CIPC_CODE'||chr(9)||

'NBBPOSN_COAS_CODE'||chr(9)||'NBBPOSN_SGRP_CODE'||chr(9)||'NBBPOSN_PGRP_CODE'||chr(9)||'NBBPOSN_WKSH_CODE'|| chr(9)||

'NBBPOSN_PFOC_CODE'||chr(9)||'NBBPOSN_PNOC_CODE'||chr(9)||'NBBPOSN_DOTT_CODE'||chr(9)||'NBBPOSN_CALIF_TYPE'||chr(9)||

'NBBPOSN_JBLN_CODE'||chr(9)||'NBBPOSN_BARG_CODE'||chr(9)||'NBBPOSN_PROBATION_UNITS'||chr(9)||'NBBPOSN_COMMENT'||chr(9)||

'NBBPOSN_JOBP_CODE'||chr(9)||'NBBPOSN_BPRO_CODE'||chr(9)||'NBBPOSN_USER_ID'||chr(9)||'NBBPOSN_DATA_ORIGIN'||chr(9)||

'NBBPOSN_VPDI_CODE'||chr(9)||'NBBPOSN_ESOC_CODE'||chr(9)||'NBBPOSN_ECIP_CODE'||chr(9)||'NBBPOSN_GUID';

DBMS_OUTPUT.PUT_LINE (v_wstring);

utl_file.put_line(wfile_handle,v_wstring);

v_wstring := trans_b_rec.POSN_NBR||chr(9)||'A'||chr(9)||trans_b_rec.POSN_EXTENDED_TITLE||chr(9)||trans_b_rec.POSN_EFFECTIVE_DATE||chr(9)||trans_b_rec.POSN_SINGLE_POOLED||chr(9)||

trans_b_rec.POSN_PCLS_CODE||chr(9)||trans_b_rec.POSN_ECLS_CODE||chr(9)||ntrpcls_rec.NTRPCLS_TABLE||chr(9)||trans_b_rec.POSN_PAY_GRADE||chr(9)||

100||chr(9)||ptrecls_rec.PTRECLS_BUDGET_ROLL_IND||chr(9)||v_date||chr(9)||ptrecls_rec.PTRECLS_PREMIUM_ROLL_IND||chr(9)||

v_date||chr(9)||ntrpcls_rec.NTRPCLS_EXEMPT_IND||chr(9)||ntrpcls_rec.NTRPCLS_ACCRUE_SENIORITY_IND||chr(9)||'P'||chr(9)||

null||chr(9)||null||chr(9)||

null||chr(9)||v_nbbposn_auth_number||chr(9)||null||chr(9)||null||chr(9)||

trans_b_rec.POSN_COAS_CODE||chr(9)||ntrpcls_rec.NTRPCLS_SGRP_CODE||chr(9)||ntrpcls_rec.NTRPCLS_PGRP_CODE||chr(9)||null||chr(9)||

trans_b_rec.POSN_FOC_CODE||chr(9)||null||chr(9)||null||chr(9)||null||chr(9)||

null||chr(9)||null||chr(9)||null||chr(9)||v_nbbposn_comment||chr(9)||

null||chr(9)||null||chr(9)||'TT_HR_PASS'||chr(9)||null||chr(9)||

null||chr(9)||ntrpcls_rec.NTRPCLS_ESOC_CODE||chr(9)||ntrpcls_rec.NTRPCLS_ECIP_CODE||chr(9)||null;

DBMS_OUTPUT.PUT_LINE (v_wstring);

utl_file.put_line(wfile_handle,v_wstring);

OPEN CURSOR_TRANSFUNDING(trans_b_rec.TRANS_ID);

   FETCH CURSOR_TRANSFUNDING INTO transfunding_rec;

   DBMS_OUTPUT.PUT_LINE (' transfunding_rec: '||transfunding_rec.USER_ID);

CLOSE CURSOR_TRANSFUNDING;



IF(ptrecls_rec.PTRECLS_PICT_CODE = 'MN') THEN
  v_pay_num := 12;
  v_nbrptot_base_units := 12;
  v_NBRPTOT_BUDGET := trans_b_rec.POSN_RATE_OF_PAY;
  v_nbrptot_budg_basis :=  trans_b_rec.POSN_FTE *  v_pay_num;
  v_nbrptot_ann_basis  :=  ptrecls_rec.PTRECLS_ANN_BASIS;
  v_nbrptot_appt_pct   :=  100;
  DBMS_OUTPUT.PUT_LINE ('MN'||chr(9)||v_pay_num||chr(9)||v_nbrptot_base_units);
ELSIF(ptrecls_rec.PTRECLS_PICT_CODE = 'SM') THEN
  v_pay_num := 24;
  v_nbrptot_base_units := 24;
  v_NBRPTOT_BUDGET := trans_b_rec.POSN_FTE * trans_b_rec.POSN_RATE_OF_PAY *2080.08;
  v_nbrptot_budg_basis :=  trans_b_rec.POSN_FTE *  v_pay_num;
  v_nbrptot_ann_basis  :=  ptrecls_rec.PTRECLS_ANN_BASIS;
  v_nbrptot_appt_pct   :=  100;
  DBMS_OUTPUT.PUT_LINE ('SM'||chr(9)||v_pay_num||chr(9)||v_nbrptot_base_units);
ELSIF(ptrecls_rec.PTRECLS_PICT_CODE = 'NS') THEN 
  DBMS_OUTPUT.PUT_LINE ('NS');   
  v_NBRPTOT_BUDGET     := 0;
  v_nbrptot_budg_basis := 0;
  v_nbrptot_ann_basis  := 0;
  v_nbrptot_base_units := 0; 
  v_nbrptot_appt_pct   := 0; 
END IF;

IF((ptrecls_rec.PTRECLS_CODE = 'F4') or (ptrecls_rec.PTRECLS_CODE = 'F1') ) THEN
  v_nbrptot_budg_basis := 9 * trans_b_rec.POSN_FTE;
  DBMS_OUTPUT.PUT_LINE ('PTRECLS_CODE: '||chr(9)||v_nbrptot_budg_basis);
END IF;



IF(trans_b_rec.POSN_FTE = 0)       THEN
DBMS_OUTPUT.PUT_LINE ('POSN_FTE '||chr(9)||trans_b_rec.POSN_FTE);
    v_nbrptot_budg_basis := 0;
    v_nbrptot_ann_basis  := 0;
    v_nbrptot_base_units := 0;
    v_nbrptot_appt_pct   := 0;
END IF;

v_wstring := 'NBRPTOT_POSN'||chr(9)||'NBRPTOT_FISC_CODE'||chr(9)||'NBRPTOT_EFFECTIVE_DATE'||chr(9)||'NBRPTOT_FTE'||chr(9)||

        'NBRPTOT_ORGN_CODE'||chr(9)||'NBRPTOT_ACTIVITY_DATE'||chr(9)||'NBRPTOT_BUDG_BASIS'||chr(9)||'NBRPTOT_ANN_BASIS'||chr(9)||

        'NBRPTOT_BASE_UNITS'||chr(9)||'NBRPTOT_APPT_PCT'||chr(9)||'NBRPTOT_CREATE_JFTE_IND'||chr(9)||

        'NBRPTOT_STATUS'||chr(9)||'NBRPTOT_COAS_CODE'||chr(9)||'NBRPTOT_BUDGET'||chr(9)||

        'NBRPTOT_ENCUMB'||chr(9)||'NBRPTOT_EXPEND'||chr(9)||'NBRPTOT_OBUD_CODE'||chr(9)||'NBRPTOT_OBPH_CODE'||chr(9)||

        'NBRPTOT_SGRP_CODE'||chr(9)||'NBRPTOT_BUDGET_FRNG'||chr(9)||'NBRPTOT_ENCUMB_FRNG'||chr(9)||'NBRPTOT_EXPEND_FRNG'||chr(9)||

        'NBRPTOT_ACCI_CODE_FRNG'||chr(9)||'NBRPTOT_FUND_CODE_FRNG'||chr(9)||'NBRPTOT_ORGN_CODE_FRNG'||chr(9)||'NBRPTOT_ACCT_CODE_FRNG'||chr(9)||

        'NBRPTOT_PROG_CODE_FRNG'||chr(9)||'NBRPTOT_ACTV_CODE_FRNG'||chr(9)||'NBRPTOT_LOCN_CODE_FRNG'||chr(9)||'NBRPTOT_RECURRING_BUDGET'||chr(9)||

        'NBRPTOT_COMMENT'||chr(9)||'NBRPTOT_USER_ID'||chr(9)||'NBRPTOT_DATA_ORIGIN'||chr(9)||'NBRPTOT_VPDI_CODE';
        
DBMS_OUTPUT.PUT_LINE (v_wstring);

utl_file.put_line(wfile_handle,v_wstring);        
        
OPEN CURSOR_FISCYEAR(trans_b_rec.POSN_COAS_CODE);

    LOOP
        FETCH CURSOR_FISCYEAR
            BULK COLLECT INTO l_FISC_YEAR,
                              l_BUDGET_ID,
                              l_BUDGET_PHASE,
                              l_BUDGET_STATUS
            LIMIT 1000;
            DBMS_OUTPUT.PUT_LINE('l_FISC_YEAR.COUNT'||chr(9)||l_FISC_YEAR.COUNT);
            FOR indx IN 1 .. l_FISC_YEAR.COUNT
        LOOP
          v_FISC_YEAR          := '20'||l_FISC_YEAR(indx);
          v_NTRPCLS_SGRP_CODE  := 'FY'||l_FISC_YEAR(indx);

          DBMS_OUTPUT.PUT_LINE('1: ACTIVITY_DATE'||chr(9)||trans_b_rec.ACTIVITY_DATE);

          DBMS_OUTPUT.PUT_LINE('2: v_FISC_YEAR'||chr(9)||v_FISC_YEAR);

          IF (trans_b_rec.POSN_COAS_CODE = 'E') then
            SELECT LISTAGG(COMMENT_DESC, ' ') WITHIN GROUP (ORDER BY ACTIVITY_DATE desc) into v_nbbposn_comment
            from tt_hr_pass.nc_pass_comments_r where AREA = 'budget' and NC_PASS_TRANS_B_ID = trans_b_rec.TRANS_ID  and user_id <> 'NPR System';
          ELSE
            v_nbbposn_comment := 'Position inserted by PASS '||p_trans_no||' with Eff Date '||trans_b_rec.POSN_EFFECTIVE_DATE||' on '||v_date||' with FTE as '||trans_b_rec.POSN_FTE||' , Salary as '||v_NBRPTOT_BUDGET;
          END IF;
          DBMS_OUTPUT.PUT_LINE ('l_FISC_YEAR'||chr(9)||l_FISC_YEAR(indx)||chr(9)||'v_FISC_YEAR'||chr(9)||v_FISC_YEAR||chr(9)||
          'l_BUDGET_ID'||chr(9)||l_BUDGET_ID(indx)||chr(9)||
          'l_BUDGET_PHASE'||chr(9)||l_BUDGET_PHASE(indx)||chr(9)||
          'l_BUDGET_STATUS'||chr(9)||l_BUDGET_STATUS(indx)||chr(9)||
          'v_ptrcaln_start_date'||chr(9)||v_ptrcaln_start_date||chr(9)||
          'trans_b_rec.POSN_EFFECTIVE_DATE'||chr(9)||trans_b_rec.POSN_EFFECTIVE_DATE||chr(9)||
          'v_eff_date'||chr(9)||v_eff_date||chr(9)||
          'v_nbrptot_budg_basis:'||chr(9)||v_nbrptot_budg_basis
          );
          SELECT TO_CHAR(trans_b_rec.POSN_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
          SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.POSN_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
          dbms_output.put_line('1: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);
          
          IF( (v_FISC_YEAR > v_extract_year  ) OR 
          ( (trans_b_rec.POSN_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693

              IF (l_BUDGET_STATUS(indx) = 'W') THEN
			  
					v_create_year := (TO_NUMBER(v_FISC_YEAR)) - 1;
					DBMS_OUTPUT.PUT_LINE ('v_create_year: '||v_create_year);
					SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(v_create_year)) )  into v_NBRPTOT_EFFECTIVE_DATE FROM dual;
					DBMS_OUTPUT.PUT_LINE ('v_NBRPTOT_EFFECTIVE_DATE: '||v_NBRPTOT_EFFECTIVE_DATE);
                                                 
                dbms_output.put_line( 'testing: '||chr(10)||
                'indx: '||indx||'l_BUDGET_STATUS(indx): '||l_BUDGET_STATUS(indx)|| ' l_FISC_YEAR(indx): ' ||l_FISC_YEAR(indx) );
              ELSE   
                v_NBRPTOT_EFFECTIVE_DATE :=  trans_b_rec.POSN_EFFECTIVE_DATE;  
              END IF; 
              dbms_output.put_line( 'v_NBRPTOT_EFFECTIVE_DATE: '||v_NBRPTOT_EFFECTIVE_DATE );
              
              INSERT INTO NBRPTOT
              (
              NBRPTOT_POSN, NBRPTOT_FISC_CODE, NBRPTOT_EFFECTIVE_DATE, NBRPTOT_FTE,
    
              NBRPTOT_ORGN_CODE, NBRPTOT_ACTIVITY_DATE, NBRPTOT_BUDG_BASIS, NBRPTOT_ANN_BASIS,
    
              NBRPTOT_BASE_UNITS, NBRPTOT_APPT_PCT, NBRPTOT_CREATE_JFTE_IND,
    
               NBRPTOT_STATUS, NBRPTOT_COAS_CODE, NBRPTOT_BUDGET,
    
              NBRPTOT_ENCUMB, NBRPTOT_EXPEND, NBRPTOT_OBUD_CODE, NBRPTOT_OBPH_CODE,
    
              NBRPTOT_SGRP_CODE, NBRPTOT_BUDGET_FRNG, NBRPTOT_ENCUMB_FRNG, NBRPTOT_EXPEND_FRNG,
    
              NBRPTOT_ACCI_CODE_FRNG, NBRPTOT_FUND_CODE_FRNG, NBRPTOT_ORGN_CODE_FRNG, NBRPTOT_ACCT_CODE_FRNG,
    
              NBRPTOT_PROG_CODE_FRNG, NBRPTOT_ACTV_CODE_FRNG, NBRPTOT_LOCN_CODE_FRNG, NBRPTOT_RECURRING_BUDGET,
    
              NBRPTOT_COMMENT, NBRPTOT_USER_ID, NBRPTOT_DATA_ORIGIN, NBRPTOT_VPDI_CODE
              )
              VALUES
              (
              v_nbbposn_posn, v_FISC_YEAR, v_NBRPTOT_EFFECTIVE_DATE, trans_b_rec.POSN_FTE,
    
              trans_b_rec.POSN_ORGN_CODE, v_date, v_nbrptot_budg_basis, v_nbrptot_ann_basis,
    
              v_nbrptot_base_units, v_nbrptot_appt_pct, ptrecls_rec.PTRECLS_CREATE_JFTE_IND,
    
              l_BUDGET_STATUS(indx), trans_b_rec.POSN_COAS_CODE, v_NBRPTOT_BUDGET,
    
              null, null, l_BUDGET_ID(indx), l_BUDGET_PHASE(indx),
    
              v_NTRPCLS_SGRP_CODE, null, null, null,
    
              null, null, null, null,
    
              null, null, null, null,
    
              v_nbbposn_comment, 'TT_HR_PASS', null, null
              );

        END IF;   --HPSS-1693

        v_wstring := trans_b_rec.POSN_NBR||chr(9)||v_FISC_YEAR||chr(9)||trans_b_rec.POSN_EFFECTIVE_DATE||chr(9)||trans_b_rec.POSN_FTE||chr(9)||

        trans_b_rec.POSN_ORGN_CODE||chr(9)||v_date||chr(9)||v_nbrptot_budg_basis||chr(9)||v_nbrptot_ann_basis||chr(9)||

        v_nbrptot_base_units||chr(9)||v_nbrptot_appt_pct||chr(9)||ptrecls_rec.PTRECLS_CREATE_JFTE_IND||chr(9)||

        l_BUDGET_STATUS(indx)||chr(9)||trans_b_rec.POSN_COAS_CODE||chr(9)||trans_b_rec.POSN_RATE_OF_PAY||chr(9)||

        null||chr(9)||null||chr(9)||l_BUDGET_ID(indx)||chr(9)||l_BUDGET_PHASE(indx)||chr(9)||

        ntrpcls_rec.NTRPCLS_SGRP_CODE||chr(9)||null||chr(9)||null||chr(9)||null||chr(9)||

        null||chr(9)||null||chr(9)||null||chr(9)||null||chr(9)||

        null||chr(9)||null||chr(9)||null||chr(9)||null||chr(9)||

        NULL||chr(9)||'TT_HR_PASS'||chr(9)||null||chr(9)||null;

        DBMS_OUTPUT.PUT_LINE (v_wstring);

        utl_file.put_line(wfile_handle,v_wstring);

        END LOOP;



  EXIT WHEN CURSOR_FISCYEAR%NOTFOUND;

  END LOOP;

CLOSE CURSOR_FISCYEAR;

        v_wstring := 'NBRPLBD_POSN'||chr(9)||'NBRPLBD_FISC_CODE'||chr(9)||'NBRPLBD_PERCENT'||chr(9)||'NBRPLBD_ACTIVITY_DATE'||chr(9)||

        'NBRPLBD_COAS_CODE'||chr(9)||'NBRPLBD_ACCI_CODE'||chr(9)||

        'NBRPLBD_FUND_CODE'||chr(9)||'NBRPLBD_ORGN_CODE'||chr(9)||'NBRPLBD_ACCT_CODE'||chr(9)||'NBRPLBD_PROG_CODE'||chr(9)||

        'NBRPLBD_ACTV_CODE'||chr(9)||'NBRPLBD_LOCN_CODE'||chr(9)||'NBRPLBD_ACCT_CODE_EXTERNAL'||chr(9)||'NBRPLBD_OBUD_CODE'||chr(9)||

        'NBRPLBD_OBPH_CODE'||chr(9)||'NBRPLBD_CHANGE_IND'||chr(9)||'NBRPLBD_PROJ_CODE'||chr(9)||'NBRPLBD_CTYP_CODE'||chr(9)||

        'NBRPLBD_BUDGET'||chr(9)||'NBRPLBD_BUDGET_TO_POST'||chr(9)||'NBRPLBD_USER_ID'||chr(9)||'NBRPLBD_DATA_ORIGIN'||chr(9)||

        'NBRPLBD_VPDI_CODE';
        
       DBMS_OUTPUT.PUT_LINE (v_wstring);

       utl_file.put_line(wfile_handle,v_wstring);


OPEN CURSOR_NBRPLBD_FISCYEAR(trans_b_rec.POSN_COAS_CODE, p_trans_no );
LOOP        --END LOOP;   -- CURSOR_NBRPLBD_FISCYEAR(trans_b_rec.PASS_COAS_CODE, pass_trans_no );
            FETCH CURSOR_NBRPLBD_FISCYEAR
            BULK COLLECT INTO l_FISC_YEAR,
                              l_BUDGET_ID,
                              l_BUDGET_PHASE,
                              l_BUDGET_STATUS,
                              l_PASS_POSN_NBR,
                              l_PASS_COAS_CODE, 
                              l_PASS_FUND_CODE, 
                              l_PASS_ORGN_CODE,
                              
                              l_PASS_ACCT_CODE, 
            
                              l_PASS_POSN_PROG_CODE,                 
                              l_PASS_POSN_CURR_ACCT_PERC  
            LIMIT 1000;
            
            FOR indx IN 1 .. l_FISC_YEAR.COUNT       --END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
            
             
                                 
            LOOP        --END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
            
              v_FISC_YEAR := 20 ||l_FISC_YEAR(indx);
              
              v_NBRPLBD_BUDGET :=   ( (v_NBRPTOT_BUDGET * l_PASS_POSN_CURR_ACCT_PERC(indx) ) / 100);
              
              
              SELECT TO_CHAR(trans_b_rec.POSN_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
              SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.POSN_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
              dbms_output.put_line('1: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);
          
              IF( (v_FISC_YEAR > v_extract_year  ) OR 
              ( (trans_b_rec.POSN_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
              
                insert into NBRPLBD(
          
                NBRPLBD_POSN,  NBRPLBD_FISC_CODE, NBRPLBD_PERCENT,NBRPLBD_ACTIVITY_DATE,
    
                NBRPLBD_COAS_CODE, NBRPLBD_ACCI_CODE,
    
                NBRPLBD_FUND_CODE, NBRPLBD_ORGN_CODE, NBRPLBD_ACCT_CODE, NBRPLBD_PROG_CODE,
    
                NBRPLBD_ACTV_CODE, NBRPLBD_LOCN_CODE, NBRPLBD_ACCT_CODE_EXTERNAL, NBRPLBD_OBUD_CODE,
    
                NBRPLBD_OBPH_CODE,  NBRPLBD_CHANGE_IND, NBRPLBD_PROJ_CODE, NBRPLBD_CTYP_CODE,
    
                NBRPLBD_BUDGET, NBRPLBD_BUDGET_TO_POST, NBRPLBD_USER_ID, NBRPLBD_DATA_ORIGIN,
    
                NBRPLBD_VPDI_CODE)
                VALUES
                (
    
                l_PASS_POSN_NBR(indx), v_FISC_YEAR, l_PASS_POSN_CURR_ACCT_PERC(indx), v_date,
    
                l_PASS_COAS_CODE(indx), null,
    
                l_PASS_FUND_CODE(indx), l_PASS_ORGN_CODE(indx), l_PASS_ACCT_CODE(indx), l_PASS_POSN_PROG_CODE(indx),
    
                null, null, null, l_BUDGET_ID(indx),
    
                l_BUDGET_PHASE(indx),  null, null, null,
    
                v_NBRPLBD_BUDGET, 0, 'TT_HR_PASS', NULL,
    
                NULL
    
                );
              
                v_wstring :=  l_PASS_POSN_NBR(indx)||chr(9)||v_FISC_YEAR||chr(9)||l_PASS_POSN_CURR_ACCT_PERC(indx)||chr(9)||v_date||chr(9)||
      
                  l_PASS_COAS_CODE(indx)||chr(9)||null||chr(9)||
      
                  l_PASS_FUND_CODE(indx)||chr(9)||l_PASS_ORGN_CODE(indx)||chr(9)||l_PASS_ACCT_CODE(indx)||chr(9)||l_PASS_POSN_PROG_CODE(indx)||chr(9)||
      
                  null||chr(9)||null||chr(9)||null||chr(9)||l_BUDGET_ID(indx)||chr(9)||
      
                  l_BUDGET_PHASE(indx)||chr(9)||null||chr(9)||null||chr(9)||null||chr(9)||
      
                  v_NBRPLBD_BUDGET||chr(9)||NULL||chr(9)||'TT_HR_PASS'||chr(9)||NULL||chr(9)||
      
                  NULL;
                
                DBMS_OUTPUT.PUT_LINE (v_wstring);
    
                utl_file.put_line(wfile_handle,v_wstring);
              END IF; -- HPSS-1693
            
            
            END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
                
EXIT WHEN CURSOR_NBRPLBD_FISCYEAR%NOTFOUND;

END LOOP;   -- CURSOR_NBRPLBD_FISCYEAR(trans_b_rec.PASS_COAS_CODE, pass_trans_no );

Update  TT_HR_PASS.NC_PASS_TRANS_B
set     TRANS_STATUS = 'U'  ,
        BNR_UPLOAD   = 'Y'
where TRANS_NO = p_trans_no;

COMMIT;

SELECT TRANS_STATUS, POSN_NBR
  INTO v_trans_holding_status, v_trans_holding_posn_nbr
  FROM TT_HR_PASS.NC_PASS_TRANS_B
 WHERE TRANS_NO = p_trans_no;


IF v_trans_holding_status = 'U' THEN
 P_UPDATE_EPM_PASS_STATUS(p_trans_no, v_trans_holding_posn_nbr, u_id, v_holding_status);
  
  IF v_holding_status = 'success' THEN
   rtn_flag := 'S'; --The Return Flag is Set to Success if the package is executed successfully
  ELSIF v_holding_status = 'empty' THEN
    rtn_flag := 'N'; --The Return Flag is Set to Not Success if the jv records are not submitted
  ELSE
    rtn_flag := 'E'; --The Return Flag is Set to Error if the package has an error
  END IF; 
END IF;


if utl_file.is_open (wfile_handle) then
  utl_file.fclose (wfile_handle);
  DBMS_OUTPUT.PUT_LINE ('File Closed : '||v_file);
end if;

select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
   into   v_eprint_user
                from   dual;
   DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

    select gjbpseq.nextval
       into v_one_up
    from DUAL;

    GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
          ,'p_pass_banner_update'     -- e-Print Report definition (case sensitive)
          ,'p_pass_banner_update.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
          ,v_eprint_user            -- repository name
          ,v_eprint_user);          -- user id (same as repository name)
    DBMS_OUTPUT.PUT_LINE('Sending eprint report');
    DBMS_OUTPUT.PUT_LINE (' Completed.');
--The Return Flag is Set to Success if the package is executed successfully
--rtn_flag := 'S';


EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                       ROLLBACK TO s_pass_update_banner;
                       --The Return Flag is Set to E if the package experiences an error
                         rtn_flag := 'E';
                         err_msg := ('ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                         DBMS_OUTPUT.PUT_LINE(err_msg);                                
                         /*v_file := 'p_pass_error.xls';
                         wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');
                         err_msg := 'Process'||chr(9)||'p_np_banner_upd';
                         utl_file.put_line(wfile_handle,err_msg);
                         err_msg := 'Transaction No'||chr(9)||p_trans_no;
                         utl_file.put_line(wfile_handle,err_msg);
                         err_msg := ('ERROR in p_np_banner_upd '||'ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                         utl_file.put_line(wfile_handle,err_msg);
                         
                         if utl_file.is_open (wfile_handle) then
                           utl_file.fclose (wfile_handle);
                           DBMS_OUTPUT.PUT_LINE ('Err File Closed : '||v_file);
                         end if;
                         select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
                         into   v_eprint_user
                                      from   dual;
                         DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

                          select gjbpseq.nextval
                             into v_one_up
                          from DUAL;

                          GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
                                ,'p_pass_error'     -- e-Print Report definition (case sensitive)
                                ,'p_pass_error.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
                                ,v_eprint_user            -- repository name
                                ,v_eprint_user);          -- user id (same as repository name)
                          DBMS_OUTPUT.PUT_LINE('Sending eprint error report');
                          DBMS_OUTPUT.PUT_LINE (' Completed.');    
                         */
                          insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','p_np_banner_upd',
                          p_trans_no,u_id
                          );


                     END;

--1
END;


----------------------------------------------------------------------------------------------
-- OBJECT NAME: p_np_posn_upd
-- PRODUCT....: HR
-- USAGE......: Update NBAPOSN for New Position Transaction
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
-- This procedure is based on the requirement HPSS-1783, where NBAPOSN will be updated at the budget level for all Charts
-- For Chart's T S and H budget will be teh final level of approval, whereas for Chart E budget will NOT be the final level of approval.
--------------------------------------------------------------------------------------------
PROCEDURE p_np_posn_upd(p_trans_no IN varchar2,  u_id IN  varchar2, rtn_flag OUT varchar2) IS
v_date                                                              date;
v_nbbposn_posn_bnr                                                  NBBPOSN.NBBPOSN_POSN%TYPE; -- used in checking if position already exists in banner
v_nbbposn_posn_no                                                   NUMBER;-- used in checking if position already exists in banner
v_NBBPOSN_FLG                                                       varchar2(1);
v_nbbposn_comment                                                   NBBPOSN.NBBPOSN_COMMENT%TYPE;
v_eff_date                                                          NBRPTOT.NBRPTOT_EFFECTIVE_DATE%TYPE;
v_nbbposn_auth_number                                               NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE;
v_nbbposn_begin_date                                                NBBPOSN.NBBPOSN_BEGIN_DATE%TYPE; --HPSS-1784
v_nbbposn_sgrp_code                                                 NBBPOSN.NBBPOSN_SGRP_CODE%TYPE; --HPSS-1763
v_PTRECLS_CODE                                                      PTRECLS.PTRECLS_CODE%TYPE;
v_PTRECLS_PICT_CODE                                                 PTRECLS.PTRECLS_PICT_CODE%TYPE;
v_PTRECLS_BUDGET_ROLL_IND                                           PTRECLS.PTRECLS_BUDGET_ROLL_IND%TYPE;
v_PTRECLS_PREMIUM_ROLL_IND                                          PTRECLS.PTRECLS_PREMIUM_ROLL_IND%TYPE;
v_NTRPCLS_CODE                                                      NTRPCLS.NTRPCLS_CODE%TYPE;
v_NTRPCLS_TABLE                                                     NTRPCLS.NTRPCLS_TABLE%TYPE;
v_NTRPCLS_EXEMPT_IND                                                NTRPCLS.NTRPCLS_EXEMPT_IND%TYPE;
sql_stmt                                                            VARCHAR2(2500);
v_add_comment                                                       varchar2(2000);
v_comment                                                           varchar2(2000);
v_NTRPCLS_ACCRUE_SENIORITY_IND                                      NTRPCLS.NTRPCLS_ACCRUE_SENIORITY_IND%TYPE;
v_NTRPCLS_ESOC_CODE                                                 NTRPCLS.NTRPCLS_ESOC_CODE%TYPE;
v_NTRPCLS_ECIP_CODE                                                 NTRPCLS.NTRPCLS_ECIP_CODE%TYPE;
v_NTRPCLS_PGRP_CODE                                                 NTRPCLS.NTRPCLS_PGRP_CODE%TYPE;
v_FISC_YEAR                                                         varchar2(4);
v_NTRPCLS_SGRP_CODE                                                 NTRPCLS.NTRPCLS_SGRP_CODE%TYPE;
v_POSN_EXTENDED_TITLE                                               TT_HR_PASS.NC_PASS_TRANS_B.POSN_EXTENDED_TITLE%TYPE;
v_POSN_SINGLE_POOLED                                                TT_HR_PASS.NC_PASS_TRANS_B.POSN_SINGLE_POOLED%TYPE;
v_POSN_PCLS_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_PCLS_CODE%TYPE;
v_POSN_ECLS_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_ECLS_CODE%TYPE;
v_POSN_PAY_GRADE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_PAY_GRADE%TYPE;
v_POSN_COAS_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE;
v_POSN_FOC_CODE                                                     TT_HR_PASS.NC_PASS_TRANS_B.POSN_FOC_CODE%TYPE;
v_BO_APPROVER                                                       TT_HR_PASS.NC_PASS_TRANS_B.BO_APPROVER%TYPE;
v_POSN_EFFECTIVE_DATE                                               TT_HR_PASS.NC_PASS_TRANS_B.POSN_EFFECTIVE_DATE%TYPE;
v_PASS_POSN_NBR                                                     TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE;
v_APPROVAL_DATE                                                     TT_HR_PASS.NC_PASS_TRANS_B.APPROVAL_DATE%TYPE;
v_NBBPOSN_STATUS                                                    NBBPOSN.NBBPOSN_STATUS%TYPE;
v_curr_NBBPOSN_TITLE                                                NBBPOSN.NBBPOSN_TITLE%TYPE;
v_curr_NBBPOSN_BEGIN_DATE                                           NBBPOSN.NBBPOSN_BEGIN_DATE%TYPE; 
v_curr_NBBPOSN_TYPE                                                 NBBPOSN.NBBPOSN_TYPE%TYPE;
v_curr_NBBPOSN_PCLS_CODE                                            NBBPOSN.NBBPOSN_PCLS_CODE%TYPE;
v_curr_NBBPOSN_ECLS_CODE                                            NBBPOSN.NBBPOSN_ECLS_CODE%TYPE;
v_curr_NBBPOSN_TABLE                                                NBBPOSN.NBBPOSN_TABLE%TYPE;
v_curr_NBBPOSN_GRADE                                                NBBPOSN.NBBPOSN_GRADE%TYPE;
v_curr_NBBPOSN_ROLL_IND                                             NBBPOSN.NBBPOSN_ROLL_IND%TYPE;
v_curr_NBBPOSN_ACTIVITY_DATE                                        NBBPOSN.NBBPOSN_ACTIVITY_DATE%TYPE;
v_curr_NBBPOSN_PREMIUM_ROLL_IND                                     NBBPOSN.NBBPOSN_PREMIUM_ROLL_IND%TYPE;
v_curr_NBBPOSN_CHANGE_DATE_TIME                                     NBBPOSN.NBBPOSN_CHANGE_DATE_TIME%TYPE;
v_curr_NBBPOSN_EXEMPT_IND                                           NBBPOSN.NBBPOSN_EXEMPT_IND%TYPE;
v_curr_NBBPOSN_ACCRUE_SENIORITY_IND                                 NBBPOSN.NBBPOSN_ACCRUE_SENIORITY_IND%TYPE;
v_curr_NBBPOSN_AUTH_NUMBER                                          NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE;
v_curr_NBBPOSN_COAS_CODE                                            NBBPOSN.NBBPOSN_COAS_CODE%TYPE;
v_curr_NBBPOSN_SGRP_CODE                                            NBBPOSN.NBBPOSN_SGRP_CODE%TYPE;
v_curr_NBBPOSN_PGRP_CODE                                            NBBPOSN.NBBPOSN_PGRP_CODE%TYPE;
v_curr_NBBPOSN_PFOC_CODE                                            NBBPOSN.NBBPOSN_PFOC_CODE%TYPE;
v_curr_NBBPOSN_ESOC_CODE                                            NBBPOSN.NBBPOSN_ESOC_CODE%TYPE;
v_curr_NBBPOSN_ECIP_CODE                                            NBBPOSN.NBBPOSN_ECIP_CODE%TYPE;


BEGIN 
--1
savepoint  s_pass_update_banner;
SELECT SYSDATE into v_date FROM DUAL;

DBMS_OUTPUT.PUT_LINE ('TRANSACTION NUMBER'||chr(9)||p_trans_no);

DBMS_OUTPUT.PUT_LINE ('DATE'||chr(9)||v_date);

SELECT POSN_NBR, POSN_EXTENDED_TITLE, POSN_SINGLE_POOLED, 
POSN_PCLS_CODE,  POSN_ECLS_CODE, POSN_PAY_GRADE, 
POSN_COAS_CODE, POSN_FOC_CODE, BO_APPROVER, 
POSN_EFFECTIVE_DATE , APPROVAL_DATE
INTO 
v_PASS_POSN_NBR, v_POSN_EXTENDED_TITLE, v_POSN_SINGLE_POOLED,  
v_POSN_PCLS_CODE,      v_POSN_ECLS_CODE,     v_POSN_PAY_GRADE,     
v_POSN_COAS_CODE,  v_POSN_FOC_CODE,      v_BO_APPROVER,        
v_POSN_EFFECTIVE_DATE, v_APPROVAL_DATE
       
FROM TT_HR_PASS.NC_PASS_TRANS_B
     WHERE TRANS_NO = p_trans_no
     AND BNR_UPLOAD IS NULL;

--v_nbbposn_posn    :=  v_PASS_POSN_NBR;

--Check if POSN_CODE  already exists in Banner Table

select count(*) into v_nbbposn_posn_no from  NBBPOSN
WHERE NBBPOSN_POSN =  v_PASS_POSN_NBR;
/*
if (v_nbbposn_posn_no > 0) then
v_nbbposn_posn_bnr := v_PASS_POSN_NBR;
--If the POSN_CODE exists generate new POSN_CODE
  WHILE(v_PASS_POSN_NBR =  v_nbbposn_posn_bnr) LOOP    
      DBMS_OUTPUT.PUT_LINE ('Generating new Posn Code');
      v_PASS_POSN_NBR := TT_HR_PASS.NWKPASS.GetNextPosnCode(v_POSN_COAS_CODE, v_PASS_POSN_NBR);
      
      --Check if new position number also exists in banner
      select count(*) into v_nbbposn_posn_no from  NBBPOSN
      WHERE NBBPOSN_POSN =  v_PASS_POSN_NBR;
        if (v_nbbposn_posn_no > 0) then
        v_nbbposn_posn_bnr := v_PASS_POSN_NBR;
        end if;
  END LOOP;     
end if;
*/

v_nbbposn_comment := 'Position inserted by PASS '||p_trans_no||' with Eff Date '||v_POSN_EFFECTIVE_DATE||' on '||v_date;

DBMS_OUTPUT.PUT_LINE (' v_nbbposn_comment: '||chr(9)||v_nbbposn_comment);

SELECT  NTRPCLS_CODE, NTRPCLS_TABLE, NTRPCLS_EXEMPT_IND, NTRPCLS_ACCRUE_SENIORITY_IND, NTRPCLS_ESOC_CODE, NTRPCLS_ECIP_CODE, NTRPCLS_PGRP_CODE
into v_NTRPCLS_CODE, v_NTRPCLS_TABLE, v_NTRPCLS_EXEMPT_IND, v_NTRPCLS_ACCRUE_SENIORITY_IND, v_NTRPCLS_ESOC_CODE, v_NTRPCLS_ECIP_CODE , v_NTRPCLS_PGRP_CODE
FROM NTRPCLS WHERE NTRPCLS_CODE = v_POSN_PCLS_CODE;

DBMS_OUTPUT.PUT_LINE (' v_NTRPCLS_CODE: '||chr(9)||v_NTRPCLS_CODE);

SELECT PTRECLS_CODE, PTRECLS_PICT_CODE, PTRECLS_BUDGET_ROLL_IND, PTRECLS_PREMIUM_ROLL_IND 
INTO v_PTRECLS_CODE, v_PTRECLS_PICT_CODE, v_PTRECLS_BUDGET_ROLL_IND, v_PTRECLS_PREMIUM_ROLL_IND
FROM PTRECLS WHERE PTRECLS_CODE = v_POSN_ECLS_CODE;

DBMS_OUTPUT.PUT_LINE (' v_PTRECLS_PICT_CODE: '||chr(9)||v_PTRECLS_PICT_CODE||chr(9)||' v_BO_APPROVER: '||chr(9)||v_BO_APPROVER);

IF (v_BO_APPROVER = 'PASS') THEN
        v_nbbposn_auth_number   :=  'PASS';
ELSE
        v_nbbposn_auth_number   :=  'PASS '||nvl(v_BO_APPROVER, '');

END IF;

DBMS_OUTPUT.PUT_LINE (' v_nbbposn_auth_number: '||chr(9)||v_nbbposn_auth_number);

v_eff_date  :=  getCalcEffDate(v_PTRECLS_PICT_CODE, v_date, v_POSN_EFFECTIVE_DATE);

select FISC_YEAR into  v_nbbposn_sgrp_code
from tt_hr_pass.nc_pass_fiscyear_c where BUDG_STATUS = 'A' and STATUS = 'A' and coas_code = v_POSN_COAS_CODE;   --HPSS-1763

v_nbbposn_sgrp_code := 'FY'||v_nbbposn_sgrp_code;  --HPSS-1763

v_nbbposn_begin_date := trunc(v_POSN_EFFECTIVE_DATE); --HPSS-1784

if (v_nbbposn_posn_no = 0) then --HPSS-1783

--check final approval, chart E HPSS-1859

IF ((v_APPROVAL_DATE IS NULL ) AND (v_POSN_COAS_CODE = 'E') ) THEN
	v_NBBPOSN_STATUS := 'I';
ELSE 
	v_NBBPOSN_STATUS := 'A';
END IF;
 
INSERT INTO NBBPOSN (
NBBPOSN_POSN, NBBPOSN_STATUS, NBBPOSN_TITLE, NBBPOSN_BEGIN_DATE, NBBPOSN_TYPE,

NBBPOSN_PCLS_CODE, NBBPOSN_ECLS_CODE, NBBPOSN_TABLE, NBBPOSN_GRADE,

NBBPOSN_APPT_PCT, NBBPOSN_ROLL_IND, NBBPOSN_ACTIVITY_DATE, NBBPOSN_PREMIUM_ROLL_IND,

NBBPOSN_CHANGE_DATE_TIME, NBBPOSN_EXEMPT_IND, NBBPOSN_ACCRUE_SENIORITY_IND, NBBPOSN_BUDGET_TYPE,

NBBPOSN_PLOC_CODE, NBBPOSN_END_DATE,

NBBPOSN_POSN_REPORTS, NBBPOSN_AUTH_NUMBER, NBBPOSN_STEP, NBBPOSN_CIPC_CODE,

NBBPOSN_COAS_CODE, NBBPOSN_SGRP_CODE, NBBPOSN_PGRP_CODE, NBBPOSN_WKSH_CODE,

NBBPOSN_PFOC_CODE, NBBPOSN_PNOC_CODE, NBBPOSN_DOTT_CODE, NBBPOSN_CALIF_TYPE,

NBBPOSN_JBLN_CODE, NBBPOSN_BARG_CODE, NBBPOSN_PROBATION_UNITS, NBBPOSN_COMMENT,

NBBPOSN_JOBP_CODE, NBBPOSN_BPRO_CODE, NBBPOSN_USER_ID, NBBPOSN_DATA_ORIGIN,

NBBPOSN_VPDI_CODE, NBBPOSN_ESOC_CODE, NBBPOSN_ECIP_CODE,NBBPOSN_GUID
)
Values (
v_PASS_POSN_NBR, v_NBBPOSN_STATUS, v_POSN_EXTENDED_TITLE , v_nbbposn_begin_date, v_POSN_SINGLE_POOLED,

v_POSN_PCLS_CODE , v_POSN_ECLS_CODE , v_NTRPCLS_TABLE, v_POSN_PAY_GRADE ,

100, v_PTRECLS_BUDGET_ROLL_IND , v_date, v_PTRECLS_PREMIUM_ROLL_IND,

v_date, v_NTRPCLS_EXEMPT_IND, v_NTRPCLS_ACCRUE_SENIORITY_IND , 'P',

null, null,

null, v_nbbposn_auth_number, null, null,

v_POSN_COAS_CODE, v_nbbposn_sgrp_code, v_NTRPCLS_PGRP_CODE, null,

v_POSN_FOC_CODE, null, null, null,

null, null, null, v_nbbposn_comment,

null, null, 'TT_HR_PASS', null,

null, v_NTRPCLS_ESOC_CODE , v_NTRPCLS_ECIP_CODE ,null
);

DBMS_OUTPUT.PUT_LINE ('NBBPOSN_POSN'||chr(9)||'NBBPOSN_STATUS'||chr(9)||'NBBPOSN_TITLE'||chr(9)||'NBBPOSN_BEGIN_DATE'||chr(9)||'NBBPOSN_TYPE'||chr(9)||

'NBBPOSN_PCLS_CODE'||chr(9)||'NBBPOSN_ECLS_CODE'||chr(9)||'NBBPOSN_TABLE'||chr(9)||'NBBPOSN_GRADE'||chr(9)||

'NBBPOSN_APPT_PCT'||chr(9)||'NBBPOSN_ROLL_IND'||chr(9)||'NBBPOSN_ACTIVITY_DATE'||chr(9)||'NBBPOSN_PREMIUM_ROLL_IND'||chr(9)||

'NBBPOSN_CHANGE_DATE_TIME'||chr(9)||'NBBPOSN_EXEMPT_IND'||chr(9)||'NBBPOSN_ACCRUE_SENIORITY_IND'||chr(9)||'NBBPOSN_BUDGET_TYPE'||chr(9)||

'NBBPOSN_PLOC_CODE'||chr(9)||'NBBPOSN_END_DATE'||chr(9)||

'NBBPOSN_POSN_REPORTS'||chr(9)||'NBBPOSN_AUTH_NUMBER'||chr(9)||'NBBPOSN_STEP'||chr(9)||'NBBPOSN_CIPC_CODE'||chr(9)||

'NBBPOSN_COAS_CODE'||chr(9)||'NBBPOSN_SGRP_CODE'||chr(9)||'NBBPOSN_PGRP_CODE'||chr(9)||'NBBPOSN_WKSH_CODE'|| chr(9)||

'NBBPOSN_PFOC_CODE'||chr(9)||'NBBPOSN_PNOC_CODE'||chr(9)||'NBBPOSN_DOTT_CODE'||chr(9)||'NBBPOSN_CALIF_TYPE'||chr(9)||

'NBBPOSN_JBLN_CODE'||chr(9)||'NBBPOSN_BARG_CODE'||chr(9)||'NBBPOSN_PROBATION_UNITS'||chr(9)||'NBBPOSN_COMMENT'||chr(9)||

'NBBPOSN_JOBP_CODE'||chr(9)||'NBBPOSN_BPRO_CODE'||chr(9)||'NBBPOSN_USER_ID'||chr(9)||'NBBPOSN_DATA_ORIGIN'||chr(9)||

'NBBPOSN_VPDI_CODE'||chr(9)||'NBBPOSN_ESOC_CODE'||chr(9)||'NBBPOSN_ECIP_CODE'||chr(9)||'NBBPOSN_GUID');

DBMS_OUTPUT.PUT_LINE (v_PASS_POSN_NBR||chr(9)|| 'A'||chr(9)|| v_POSN_EXTENDED_TITLE ||chr(9)|| v_nbbposn_begin_date||chr(9)|| v_POSN_SINGLE_POOLED||chr(9)||

v_POSN_PCLS_CODE ||chr(9)|| v_POSN_ECLS_CODE ||chr(9)|| v_NTRPCLS_TABLE||chr(9)|| v_POSN_PAY_GRADE ||chr(9)||

100||chr(9)|| v_PTRECLS_BUDGET_ROLL_IND ||chr(9)|| v_date||chr(9)|| v_PTRECLS_PREMIUM_ROLL_IND||chr(9)||

v_date||chr(9)|| v_NTRPCLS_EXEMPT_IND||chr(9)|| v_NTRPCLS_ACCRUE_SENIORITY_IND ||chr(9)|| 'P'||chr(9)||

null||chr(9)|| null||chr(9)||

null||chr(9)|| v_nbbposn_auth_number||chr(9)|| null||chr(9)|| null||chr(9)||

v_POSN_COAS_CODE||chr(9)|| v_nbbposn_sgrp_code||chr(9)|| v_NTRPCLS_PGRP_CODE||chr(9)|| null||chr(9)||

v_POSN_FOC_CODE||chr(9)|| null||chr(9)|| null||chr(9)|| null||chr(9)||

null||chr(9)|| null||chr(9)|| null||chr(9)|| v_nbbposn_comment||chr(9)||

null||chr(9)|| null||chr(9)|| 'TT_HR_PASS'||chr(9)|| null||chr(9)||

null||chr(9)|| v_NTRPCLS_ESOC_CODE ||chr(9)|| v_NTRPCLS_ECIP_CODE ||chr(9)||null
);

else
select NBBPOSN_TITLE, NBBPOSN_BEGIN_DATE, 	NBBPOSN_TYPE,	
NBBPOSN_PCLS_CODE, NBBPOSN_ECLS_CODE, NBBPOSN_TABLE,
NBBPOSN_GRADE, NBBPOSN_ROLL_IND, NBBPOSN_ACTIVITY_DATE,
NBBPOSN_PREMIUM_ROLL_IND, NBBPOSN_CHANGE_DATE_TIME, NBBPOSN_EXEMPT_IND,
NBBPOSN_ACCRUE_SENIORITY_IND, NBBPOSN_AUTH_NUMBER, NBBPOSN_COAS_CODE, 
NBBPOSN_SGRP_CODE, NBBPOSN_PGRP_CODE, NBBPOSN_PFOC_CODE,
NBBPOSN_ESOC_CODE, NBBPOSN_ECIP_CODE
into
v_curr_NBBPOSN_TITLE, v_curr_NBBPOSN_BEGIN_DATE, v_curr_NBBPOSN_TYPE, 
v_curr_NBBPOSN_PCLS_CODE, v_curr_NBBPOSN_ECLS_CODE, v_curr_NBBPOSN_TABLE,
v_curr_NBBPOSN_GRADE, v_curr_NBBPOSN_ROLL_IND, v_curr_NBBPOSN_ACTIVITY_DATE,
v_curr_NBBPOSN_PREMIUM_ROLL_IND, v_curr_NBBPOSN_CHANGE_DATE_TIME, v_curr_NBBPOSN_EXEMPT_IND,
v_curr_NBBPOSN_ACCRUE_SENIORITY_IND, v_curr_NBBPOSN_AUTH_NUMBER, v_curr_NBBPOSN_COAS_CODE, 
v_curr_NBBPOSN_SGRP_CODE, v_curr_NBBPOSN_PGRP_CODE, v_curr_NBBPOSN_PFOC_CODE, 
v_curr_NBBPOSN_ESOC_CODE, v_curr_NBBPOSN_ECIP_CODE                                                
from NBBPOSN
WHERE NBBPOSN_POSN = v_PASS_POSN_NBR;

dbms_output.put_line('Current/ Updated'||chr(9)||'NBBPOSN_TITLE'||chr(9)|| 
'NBBPOSN_BEGIN_DATE' ||chr(9)||'NBBPOSN_TYPE'||chr(9)||'NBBPOSN_PCLS_CODE' ||chr(9)||
'NBBPOSN_ECLS_CODE' ||chr(9)||'NBBPOSN_TABLE' ||chr(9)||'NBBPOSN_GRADE'||chr(9)||
'NBBPOSN_ROLL_IND' ||chr(9)||'NBBPOSN_ACTIVITY_DATE' ||chr(9)||'NBBPOSN_PREMIUM_ROLL_IND'||chr(9)||
'NBBPOSN_CHANGE_DATE_TIME' ||chr(9)||'NBBPOSN_EXEMPT_IND' ||chr(9)||'NBBPOSN_ACCRUE_SENIORITY_IND '||chr(9)||
'NBBPOSN_AUTH_NUMBER' ||chr(9)||'NBBPOSN_COAS_CODE '||chr(9)||'NBBPOSN_SGRP_CODE '||chr(9)||
'NBBPOSN_PGRP_CODE '||chr(9)||'NBBPOSN_PFOC_CODE '||chr(9)||'NBBPOSN_ESOC_CODE '||chr(9)||
'NBBPOSN_ECIP_CODE ');
 
dbms_output.put_line('Current'||chr(9)||v_curr_NBBPOSN_TITLE||chr(9)||                                                   
v_curr_NBBPOSN_BEGIN_DATE||chr(9)||v_curr_NBBPOSN_TYPE||chr(9)||v_curr_NBBPOSN_PCLS_CODE||chr(9)||
v_curr_NBBPOSN_ECLS_CODE||chr(9)||v_curr_NBBPOSN_TABLE||chr(9)||v_curr_NBBPOSN_GRADE||chr(9)||
v_curr_NBBPOSN_ROLL_IND||chr(9)||v_curr_NBBPOSN_ACTIVITY_DATE ||chr(9)||v_curr_NBBPOSN_PREMIUM_ROLL_IND||chr(9)||
v_curr_NBBPOSN_CHANGE_DATE_TIME||chr(9)||v_curr_NBBPOSN_EXEMPT_IND||chr(9)||v_curr_NBBPOSN_ACCRUE_SENIORITY_IND||chr(9)||
v_curr_NBBPOSN_AUTH_NUMBER||chr(9)||v_curr_NBBPOSN_COAS_CODE||chr(9)||v_curr_NBBPOSN_SGRP_CODE||chr(9)||
v_curr_NBBPOSN_PGRP_CODE||chr(9)||v_curr_NBBPOSN_PFOC_CODE||chr(9)||v_curr_NBBPOSN_ESOC_CODE||chr(9)||
v_curr_NBBPOSN_ECIP_CODE);


dbms_output.put_line('Updated'||chr(9)||v_POSN_EXTENDED_TITLE||chr(9)||  
v_nbbposn_begin_date ||chr(9)||v_POSN_SINGLE_POOLED||chr(9)||v_POSN_PCLS_CODE ||chr(9)||
v_POSN_ECLS_CODE ||chr(9)||v_NTRPCLS_TABLE ||chr(9)||v_POSN_PAY_GRADE||chr(9)||
v_PTRECLS_BUDGET_ROLL_IND ||chr(9)||v_date ||chr(9)||v_PTRECLS_PREMIUM_ROLL_IND||chr(9)||
v_date ||chr(9)||v_NTRPCLS_EXEMPT_IND ||chr(9)||v_NTRPCLS_ACCRUE_SENIORITY_IND||chr(9)||
v_nbbposn_auth_number ||chr(9)||v_POSN_COAS_CODE ||chr(9)||v_nbbposn_sgrp_code ||chr(9)||
v_NTRPCLS_PGRP_CODE ||chr(9)||v_POSN_FOC_CODE ||chr(9)||v_NTRPCLS_ESOC_CODE ||chr(9)||
v_NTRPCLS_ECIP_CODE);


sql_stmt := 'UPDATE NBBPOSN SET '; 
v_NBBPOSN_FLG := NULL;

	if (v_curr_NBBPOSN_TITLE != v_POSN_EXTENDED_TITLE) then
	    v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_TITLE = '''|| v_POSN_EXTENDED_TITLE ||'''';
                
		/*v_add_comment := 'NBBPOSN TITLE updated by PASS from '||v_POSN_EXTENDED_TITLE||' TO '||trans_b_rec.PASS_EXTENDED_TITLE||' ON '||v_date;
	
		v_comment := fstringConcat(v_comment, v_add_comment);*/
	
	end if;
	
	if (v_curr_NBBPOSN_BEGIN_DATE != v_nbbposn_begin_date) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_BEGIN_DATE = '''|| v_nbbposn_begin_date ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_TYPE != v_POSN_SINGLE_POOLED) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_TYPE = '''|| v_POSN_SINGLE_POOLED ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_PCLS_CODE  != v_POSN_PCLS_CODE) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_PCLS_CODE = '''|| v_POSN_PCLS_CODE ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_ECLS_CODE   != v_POSN_ECLS_CODE) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_ECLS_CODE = '''|| v_POSN_ECLS_CODE ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_TABLE   != v_NTRPCLS_TABLE ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_TABLE = '''|| v_NTRPCLS_TABLE  ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_GRADE   != v_POSN_PAY_GRADE ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_GRADE = '''|| v_POSN_PAY_GRADE  ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_ROLL_IND   != v_PTRECLS_BUDGET_ROLL_IND ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_ROLL_IND  = '''|| v_PTRECLS_BUDGET_ROLL_IND  ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_CHANGE_DATE_TIME   != v_date ) then
	if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_CHANGE_DATE_TIME  = '''|| v_date  ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_EXEMPT_IND   != v_NTRPCLS_EXEMPT_IND ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||'  NBBPOSN_EXEMPT_IND  = '''|| v_NTRPCLS_EXEMPT_IND  ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_ACCRUE_SENIORITY_IND   != v_NTRPCLS_ACCRUE_SENIORITY_IND ) then
		sql_stmt := sql_stmt||' , NBBPOSN_ACCRUE_SENIORITY_IND  = '''|| v_NTRPCLS_ACCRUE_SENIORITY_IND  ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_AUTH_NUMBER   != v_nbbposn_auth_number  ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_AUTH_NUMBER  = '''|| v_nbbposn_auth_number   ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_COAS_CODE   != v_POSN_COAS_CODE  ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_COAS_CODE  = '''|| v_POSN_COAS_CODE   ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_SGRP_CODE   != v_nbbposn_sgrp_code  ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_SGRP_CODE  = '''|| v_nbbposn_sgrp_code   ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_PGRP_CODE   != v_NTRPCLS_PGRP_CODE   ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_PGRP_CODE  = '''|| v_NTRPCLS_PGRP_CODE    ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_PFOC_CODE   != v_POSN_FOC_CODE   ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_PFOC_CODE  = '''|| v_POSN_FOC_CODE    ||'''';
               
	end if;
	
	if (v_curr_NBBPOSN_ESOC_CODE   != v_NTRPCLS_ESOC_CODE   ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_ESOC_CODE  = '''|| v_NTRPCLS_ESOC_CODE    ||'''';
               
	end if;
		
	if (v_curr_NBBPOSN_ECIP_CODE   != v_NTRPCLS_ECIP_CODE   ) then
		if v_NBBPOSN_FLG = 'Y' then
			sql_stmt := sql_stmt||' , ';
		end if; 
	 
		v_NBBPOSN_FLG := 'Y';
		sql_stmt := sql_stmt||' NBBPOSN_ECIP_CODE  = '''|| v_NTRPCLS_ECIP_CODE    ||'''';
               
	end if;
		
	--execute sql statement
	if v_NBBPOSN_FLG = 'Y' then
		sql_stmt := sql_stmt|| ' ,  NBBPOSN_USER_ID = ''TT_HR_PASS'''||
                    ' ,  NBBPOSN_ACTIVITY_DATE = '''|| v_date ||''''||
                    '  where NBBPOSN_POSN = '''|| p_trans_no ||'''';
		
		dbms_output.put_line('sql_stmt: '||sql_stmt);
		
		EXECUTE IMMEDIATE sql_stmt;		
		
	end if;
	
	
end if;  --HPSS-1783


rtn_flag := 'S';


EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                       ROLLBACK TO s_pass_update_banner;
                       --The Return Flag is Set to E if the package experiences an error
                         rtn_flag := 'E';
                         err_msg := ('ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                         DBMS_OUTPUT.PUT_LINE(err_msg);                                
                        
                          insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','p_np_posn_upd',
                          p_trans_no,u_id
                          );


                     END;

--1
END;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: p_np_pbud_upd
-- PRODUCT....: HR
-- USAGE......: Update Banner tables from the PASS Application
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--  This procedure will update a line into each one of the below mentioned tables  based on the New Position
-- Transaction
-- 1) One Line for each occurance of the Active Fiscal Year under NC_PASS_FISCYEAR_C Table in NBRPTOT
--     based on the Position Number
-- 2) One Line for each occurance of the Active Fiscal Year in NC_PASS_FISCYEAR_C Table in NBRPLBD
--     based on the Position Number
--------------------------------------------------------------------------------------------
PROCEDURE p_np_pbud_upd(p_trans_no IN varchar2,  u_id IN  varchar2, rtn_flag OUT varchar2) IS 
v_date                                                              date;
v_POSN_NBR                                                          TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE;
v_POSN_EFFECTIVE_DATE                                               TT_HR_PASS.NC_PASS_TRANS_B.POSN_EFFECTIVE_DATE%TYPE;
v_POSN_PCLS_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_PCLS_CODE%TYPE;
v_POSN_ECLS_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_ECLS_CODE%TYPE;
v_BO_APPROVER                                                       TT_HR_PASS.NC_PASS_TRANS_B.BO_APPROVER%TYPE;
v_POSN_COAS_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE;
v_TRANS_ID                                                          TT_HR_PASS.NC_PASS_TRANS_B.TRANS_ID%TYPE;
v_POSN_RATE_OF_PAY                                                  TT_HR_PASS.NC_PASS_TRANS_B.POSN_RATE_OF_PAY%TYPE;
v_POSN_FTE                                                          TT_HR_PASS.NC_PASS_TRANS_B.POSN_FTE%TYPE;
v_ACTIVITY_DATE                                                     TT_HR_PASS.NC_PASS_TRANS_B.ACTIVITY_DATE%TYPE;
v_POSN_ORGN_CODE                                                    TT_HR_PASS.NC_PASS_TRANS_B.POSN_ORGN_CODE%TYPE;

v_nbbposn_posn                                                      NBBPOSN.NBBPOSN_POSN%TYPE;
v_nbbposn_posn_bnr                                                  NBBPOSN.NBBPOSN_POSN%TYPE;
v_nbbposn_posn_no                                                   NUMBER;
v_nbbposn_comment                                                   NBBPOSN.NBBPOSN_COMMENT%TYPE;
v_eff_date                                                          NBRPTOT.NBRPTOT_EFFECTIVE_DATE%TYPE;
v_nbbposn_auth_number                                               NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE;
v_nbbposn_begin_date                                                NBBPOSN.NBBPOSN_BEGIN_DATE%TYPE; --HPSS-1784
v_nbbposn_sgrp_code                                                 NBBPOSN.NBBPOSN_SGRP_CODE%TYPE; --HPSS-1763
v_PTRECLS_CODE                                                      PTRECLS.PTRECLS_CODE%TYPE;
v_PTRECLS_PICT_CODE                                                 PTRECLS.PTRECLS_PICT_CODE%TYPE;
v_PTRECLS_BUDGET_ROLL_IND                                           PTRECLS.PTRECLS_BUDGET_ROLL_IND%TYPE;
v_PTRECLS_PREMIUM_ROLL_IND                                          PTRECLS.PTRECLS_PREMIUM_ROLL_IND%TYPE;
v_PTRECLS_ANN_BASIS                                                 PTRECLS.PTRECLS_ANN_BASIS%TYPE;
v_PTRECLS_CREATE_JFTE_IND                                           PTRECLS.PTRECLS_CREATE_JFTE_IND%TYPE; --pbud 

v_NTRPCLS_CODE                                                      NTRPCLS.NTRPCLS_CODE%TYPE;
v_NTRPCLS_TABLE                                                     NTRPCLS.NTRPCLS_TABLE%TYPE;
v_NTRPCLS_EXEMPT_IND                                                NTRPCLS.NTRPCLS_EXEMPT_IND%TYPE;
v_NTRPCLS_ACCRUE_SENIORITY_IND                                      NTRPCLS.NTRPCLS_ACCRUE_SENIORITY_IND%TYPE;
v_NTRPCLS_ESOC_CODE                                                 NTRPCLS.NTRPCLS_ESOC_CODE%TYPE;
v_NTRPCLS_ECIP_CODE                                                 NTRPCLS.NTRPCLS_ECIP_CODE%TYPE;
v_NTRPCLS_PGRP_CODE                                                 NTRPCLS.NTRPCLS_PGRP_CODE%TYPE;

v_FISC_YEAR                                                         varchar2(4);
v_NTRPCLS_SGRP_CODE                                                 NTRPCLS.NTRPCLS_SGRP_CODE%TYPE;
v_wstring                                                           varchar2 (6000);

v_nbrptot_budg_basis                                                NBRPTOT.NBRPTOT_BUDG_BASIS%TYPE;
v_nbrptot_ann_basis                                                 NBRPTOT.NBRPTOT_ANN_BASIS%TYPE;
v_nbrptot_base_units                                                NBRPTOT.NBRPTOT_BASE_UNITS%TYPE;
v_nbrptot_appt_pct                                                  NBRPTOT.NBRPTOT_APPT_PCT%TYPE;
v_NBRPTOT_BUDGET                                                    NUMBER(11,2);
v_NBRPTOT_EFFECTIVE_DATE                                            NBRPTOT.NBRPTOT_EFFECTIVE_DATE%TYPE;
v_APPROVAL_DATE                                                     TT_HR_PASS.NC_PASS_TRANS_B.APPROVAL_DATE%TYPE;
v_NBRPLBD_BUDGET                                                    NUMBER(11,2);
v_pay_num                                                           NUMBER;
v_ptrcaln_start_date                                                PTRCALN.PTRCALN_START_DATE%TYPE;
v_extract_date                                                      varchar2(20);      --HPSS-1693
v_extract_year                                                      varchar2(20);      --HPSS-1693
v_working_cutoff_date                                               DATE;      --HPSS-1693
v_create_year                                                       number;

type r_FISC_YEAR                       IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.FISC_YEAR%TYPE;
type r_BUDGET_STATUS                   IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_STATUS%TYPE;
type r_BUDGET_ID                       IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_ID%TYPE;
type r_BUDGET_PHASE                    IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_PHASE%TYPE;

type r_PASS_POSN_NBR                   IS TABLE OF     TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE;
type r_PASS_COAS_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE;
type r_PASS_FUND_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_FUND_CODE%TYPE;
type r_PASS_ORGN_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_ORGN_CODE%TYPE;
type r_PASS_ACCT_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_ACCT_CODE%TYPE;

type r_PASS_POSN_PROG_CODE             IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_PROG_CODE%TYPE;
type r_PASS_POSN_CURR_ACCT_PERC        IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_CURRENT_ACCT_PERCENT%TYPE;

l_FISC_YEAR                       r_FISC_YEAR;
l_BUDGET_STATUS                   r_BUDGET_STATUS;
l_BUDGET_ID                       r_BUDGET_ID;
l_BUDGET_PHASE                    r_BUDGET_PHASE;

l_PASS_POSN_NBR                   r_PASS_POSN_NBR;
l_PASS_COAS_CODE                  r_PASS_COAS_CODE;
l_PASS_FUND_CODE                  r_PASS_FUND_CODE;
l_PASS_ACCT_CODE                  r_PASS_ACCT_CODE;
l_PASS_ORGN_CODE                  r_PASS_ORGN_CODE;

l_PASS_POSN_PROG_CODE             r_PASS_POSN_PROG_CODE ;                 
l_PASS_POSN_CURR_ACCT_PERC        r_PASS_POSN_CURR_ACCT_PERC ;
type r_COMMENT_DESC                       IS TABLE OF     tt_hr_pass.nc_pass_comments_r.COMMENT_DESC%TYPE; --HPSS-1666
l_COMMENT_DESC                    r_COMMENT_DESC; --HPSS-1666




TYPE t_comment_table IS TABLE OF  VARCHAR2(2000)  -- Associative array type
INDEX BY VARCHAR2(4);
j                         varchar2(4);            -- scalar index variable

v_nbrptot_comment t_comment_table;
v_nbrplbd_comment t_comment_table;

v_holding_status varchar2(10);
v_trans_holding_status varchar2(2);
v_trans_holding_posn_nbr varchar2(6);

CURSOR CURSOR_FISCYEAR (chart IN varchar2) IS
  select FISC_YEAR, BUDG_ID, BUDG_PHASE, BUDG_STATUS
  from tt_hr_pass.nc_pass_fiscyear_c
  where coas_code = chart
  and Status = 'A';

CURSOR CURSOR_NBRPLBD_FISCYEAR (p_chart IN varchar2, p_trans_no IN varchar2) IS 
select fisc.FISC_YEAR, fisc.BUDG_ID, fisc.BUDG_PHASE, fisc.BUDG_STATUS, trans_b.POSN_NBR, trans_b.POSN_COAS_CODE,  trans_f.POSN_FUND_CODE, trans_f.POSN_ORGN_CODE,
trans_f.POSN_ACCT_CODE,  trans_f.POSN_PROG_CODE,  trans_f.POSN_CURRENT_ACCT_PERCENT
from tt_hr_pass.nc_pass_fiscyear_c fisc, tt_hr_pass.nc_pass_trans_b trans_b, tt_hr_pass.nc_pass_transfunding_r trans_f 
where 
fisc.coas_code = p_chart AND  
fisc.Status = 'A'and 
trans_b.trans_no = p_trans_no  
and trans_f.NC_PASS_TRANS_B_ID =  trans_b.TRANS_ID; 
--HPSS-1666
CURSOR Chart_E_Budget_Comments(p_trans_id IN NUMBER) IS
SELECT COMMENT_DESC from tt_hr_pass.nc_pass_comments_r 
where AREA = 'budget' and NC_PASS_TRANS_B_ID = p_trans_id  and user_id <> 'NPR System'
ORDER BY ACTIVITY_DATE desc;


BEGIN
--1

savepoint s_pass_pbud_upd;
SELECT SYSDATE into v_date FROM DUAL;

DBMS_OUTPUT.PUT_LINE ('TRANSACTION NUMBER'||chr(9)||p_trans_no);

DBMS_OUTPUT.PUT_LINE ('DATE'||chr(9)||v_date);


SELECT POSN_NBR, POSN_EFFECTIVE_DATE, POSN_PCLS_CODE,                     
POSN_ECLS_CODE, BO_APPROVER, POSN_COAS_CODE, 
TRANS_ID , POSN_RATE_OF_PAY, POSN_FTE, 
ACTIVITY_DATE, POSN_ORGN_CODE, APPROVAL_DATE                     
INTO 
v_POSN_NBR, v_POSN_EFFECTIVE_DATE , v_POSN_PCLS_CODE ,                     
v_POSN_ECLS_CODE,  v_BO_APPROVER , v_POSN_COAS_CODE, 
v_TRANS_ID, v_POSN_RATE_OF_PAY, v_POSN_FTE,
v_ACTIVITY_DATE , v_POSN_ORGN_CODE , v_APPROVAL_DATE 
FROM TT_HR_PASS.NC_PASS_TRANS_B
WHERE TRANS_NO = p_trans_no
AND BNR_UPLOAD IS NULL;

SELECT  NTRPCLS_CODE, NTRPCLS_TABLE, NTRPCLS_EXEMPT_IND, NTRPCLS_ACCRUE_SENIORITY_IND, NTRPCLS_ESOC_CODE, NTRPCLS_ECIP_CODE, NTRPCLS_PGRP_CODE
into v_NTRPCLS_CODE, v_NTRPCLS_TABLE, v_NTRPCLS_EXEMPT_IND, v_NTRPCLS_ACCRUE_SENIORITY_IND, v_NTRPCLS_ESOC_CODE, v_NTRPCLS_ECIP_CODE , v_NTRPCLS_PGRP_CODE
FROM NTRPCLS WHERE NTRPCLS_CODE = v_POSN_PCLS_CODE;

DBMS_OUTPUT.PUT_LINE (' v_NTRPCLS_CODE: '||chr(9)||v_NTRPCLS_CODE);

SELECT PTRECLS_CODE, PTRECLS_PICT_CODE, PTRECLS_BUDGET_ROLL_IND, PTRECLS_PREMIUM_ROLL_IND, PTRECLS_ANN_BASIS , PTRECLS_CREATE_JFTE_IND
INTO v_PTRECLS_CODE, v_PTRECLS_PICT_CODE, v_PTRECLS_BUDGET_ROLL_IND, v_PTRECLS_PREMIUM_ROLL_IND, v_PTRECLS_ANN_BASIS, v_PTRECLS_CREATE_JFTE_IND
FROM PTRECLS WHERE PTRECLS_CODE = v_POSN_ECLS_CODE   ;

DBMS_OUTPUT.PUT_LINE (' v_PTRECLS_PICT_CODE: '||chr(9)||v_PTRECLS_PICT_CODE||chr(9)||' v_BO_APPROVER : '||chr(9)||v_BO_APPROVER );

v_nbbposn_posn    :=  v_POSN_NBR;

v_nbbposn_comment := null;

IF(v_PTRECLS_PICT_CODE = 'MN') THEN
  v_pay_num := 12;
  v_nbrptot_base_units := 12;
  v_NBRPTOT_BUDGET := v_POSN_RATE_OF_PAY ;
  v_nbrptot_budg_basis :=  v_POSN_FTE  *  v_pay_num;
  v_nbrptot_ann_basis  :=  v_PTRECLS_ANN_BASIS;
  v_nbrptot_appt_pct   :=  100;
  DBMS_OUTPUT.PUT_LINE ('MN'||chr(9)||v_pay_num||chr(9)||v_nbrptot_base_units);
ELSIF(v_PTRECLS_PICT_CODE = 'SM') THEN
  v_pay_num := 24;
  v_nbrptot_base_units := 24;
  v_NBRPTOT_BUDGET := v_POSN_FTE  * v_POSN_RATE_OF_PAY  *2080.08;
  v_nbrptot_budg_basis :=  v_POSN_FTE  *  v_pay_num;
  v_nbrptot_ann_basis  :=  v_PTRECLS_ANN_BASIS;
  v_nbrptot_appt_pct   :=  100;
  DBMS_OUTPUT.PUT_LINE ('SM'||chr(9)||v_pay_num||chr(9)||v_nbrptot_base_units);
ELSIF(v_PTRECLS_PICT_CODE = 'NS') THEN 
  DBMS_OUTPUT.PUT_LINE ('NS');   
  v_NBRPTOT_BUDGET     := 0;
  v_nbrptot_budg_basis := 0;
  v_nbrptot_ann_basis  := 0;
  v_nbrptot_base_units := 0; 
  v_nbrptot_appt_pct   := 0; 
END IF;

IF (v_POSN_COAS_CODE = 'E') then
	--HPSS-1666
	OPEN Chart_E_Budget_Comments(v_TRANS_ID);
	LOOP 
		FETCH Chart_E_Budget_Comments BULK COLLECT INTO l_COMMENT_DESC 
		LIMIT 1000;
		DBMS_OUTPUT.PUT_LINE('l_COMMENT_DESC.COUNT: '||chr(9)||l_COMMENT_DESC.COUNT);
			FOR budg_indx IN 1 .. l_COMMENT_DESC.COUNT
			LOOP
				DBMS_OUTPUT.PUT_LINE ('l_COMMENT_DESC: '||l_COMMENT_DESC(budg_indx));
				IF (v_nbbposn_comment IS NULL ) THEN
					v_nbbposn_comment := l_COMMENT_DESC(budg_indx);
					DBMS_OUTPUT.PUT_LINE ('IF: '||v_nbbposn_comment);
				ELSE
					v_nbbposn_comment := v_nbbposn_comment||chr(10)||l_COMMENT_DESC(budg_indx);
					DBMS_OUTPUT.PUT_LINE ('ELSE: '||v_nbbposn_comment);
				END IF;
			END LOOP;
	EXIT WHEN Chart_E_Budget_Comments%NOTFOUND;		
	END LOOP;	
	CLOSE Chart_E_Budget_Comments;	
	--HPSS-1666
            
			/*SELECT LISTAGG(COMMENT_DESC, ' ') WITHIN GROUP (ORDER BY ACTIVITY_DATE desc) into v_nbbposn_comment
            from tt_hr_pass.nc_pass_comments_r where AREA = 'budget' and NC_PASS_TRANS_B_ID = v_TRANS_ID  and user_id <> 'NPR System';*/
ELSE
    v_nbbposn_comment := 'Position inserted by PASS '||p_trans_no||' with Eff Date '||v_POSN_EFFECTIVE_DATE||' on '||v_date||' with FTE as '||v_POSN_FTE ||' , Salary as '||v_NBRPTOT_BUDGET;
END IF;

DBMS_OUTPUT.PUT_LINE ('v_nbbposn_comment: '||chr(9)||v_nbbposn_comment);



IF (v_BO_APPROVER  = 'PASS') THEN
        v_nbbposn_auth_number   :=  'PASS';
ELSE
        v_nbbposn_auth_number   :=  'PASS '||nvl(v_BO_APPROVER , '');

END IF;

DBMS_OUTPUT.PUT_LINE (' v_nbbposn_auth_number: '||chr(9)||v_nbbposn_auth_number);

v_eff_date  :=  getCalcEffDate(v_PTRECLS_PICT_CODE, v_date, v_POSN_EFFECTIVE_DATE);

select FISC_YEAR into  v_nbbposn_sgrp_code
from tt_hr_pass.nc_pass_fiscyear_c where BUDG_STATUS = 'A' and STATUS = 'A' and coas_code = v_POSN_COAS_CODE;   --HPSS-1763

v_nbbposn_sgrp_code := 'FY'||v_nbbposn_sgrp_code;  --HPSS-1763

v_nbbposn_begin_date := trunc(v_POSN_EFFECTIVE_DATE); --HPSS-1784



IF (((v_PTRECLS_CODE = 'F4') or (v_PTRECLS_CODE = 'F1')) or 
	((v_PTRECLS_CODE = 'S2') AND ((v_POSN_PCLS_CODE = 'U0325') or (v_POSN_PCLS_CODE = 'U0324'))) ) THEN   --HPSS-1865
  v_nbrptot_budg_basis := 9 * v_POSN_FTE ;
  DBMS_OUTPUT.PUT_LINE ('PTRECLS_CODE: '||chr(9)||v_nbrptot_budg_basis);
END IF;



IF(v_POSN_FTE  = 0)       THEN
DBMS_OUTPUT.PUT_LINE ('POSN_FTE '||chr(9)||v_POSN_FTE );
    v_nbrptot_budg_basis := 0;
    v_nbrptot_ann_basis  := 0;
    v_nbrptot_base_units := 0;
    v_nbrptot_appt_pct   := 0;
END IF;

IF (v_PTRECLS_CODE = 'S2') THEN   --HPSS-1865
	IF ((v_POSN_PCLS_CODE != 'U0325') AND (v_POSN_PCLS_CODE != 'U0324')) THEN
	v_nbrptot_ann_basis := 12;
	END IF;
END IF;   --HPSS-1865
v_wstring := 'NBRPTOT_POSN'||chr(9)||'NBRPTOT_FISC_CODE'||chr(9)||'NBRPTOT_EFFECTIVE_DATE'||chr(9)||'NBRPTOT_FTE'||chr(9)||

        'NBRPTOT_ORGN_CODE'||chr(9)||'NBRPTOT_ACTIVITY_DATE'||chr(9)||'NBRPTOT_BUDG_BASIS'||chr(9)||'NBRPTOT_ANN_BASIS'||chr(9)||

        'NBRPTOT_BASE_UNITS'||chr(9)||'NBRPTOT_APPT_PCT'||chr(9)||'NBRPTOT_CREATE_JFTE_IND'||chr(9)||

        'NBRPTOT_STATUS'||chr(9)||'NBRPTOT_COAS_CODE'||chr(9)||'NBRPTOT_BUDGET'||chr(9)||

        'NBRPTOT_ENCUMB'||chr(9)||'NBRPTOT_EXPEND'||chr(9)||'NBRPTOT_OBUD_CODE'||chr(9)||'NBRPTOT_OBPH_CODE'||chr(9)||

        'NBRPTOT_SGRP_CODE'||chr(9)||'NBRPTOT_BUDGET_FRNG'||chr(9)||'NBRPTOT_ENCUMB_FRNG'||chr(9)||'NBRPTOT_EXPEND_FRNG'||chr(9)||

        'NBRPTOT_ACCI_CODE_FRNG'||chr(9)||'NBRPTOT_FUND_CODE_FRNG'||chr(9)||'NBRPTOT_ORGN_CODE_FRNG'||chr(9)||'NBRPTOT_ACCT_CODE_FRNG'||chr(9)||

        'NBRPTOT_PROG_CODE_FRNG'||chr(9)||'NBRPTOT_ACTV_CODE_FRNG'||chr(9)||'NBRPTOT_LOCN_CODE_FRNG'||chr(9)||'NBRPTOT_RECURRING_BUDGET'||chr(9)||

        'NBRPTOT_COMMENT'||chr(9)||'NBRPTOT_USER_ID'||chr(9)||'NBRPTOT_DATA_ORIGIN'||chr(9)||'NBRPTOT_VPDI_CODE';
        
DBMS_OUTPUT.PUT_LINE (v_wstring);

	
--HPSS-1859
IF ( (v_APPROVAL_DATE IS NOT NULL) AND (v_POSN_COAS_CODE = 'E') ) THEN
	
	Update NBBPOSN
	SET NBBPOSN_STATUS = 'A'
	WHERE NBBPOSN_POSN = v_POSN_NBR;
	
END IF;



OPEN CURSOR_FISCYEAR(v_POSN_COAS_CODE);

    LOOP
        FETCH CURSOR_FISCYEAR
            BULK COLLECT INTO l_FISC_YEAR,
                              l_BUDGET_ID,
                              l_BUDGET_PHASE,
                              l_BUDGET_STATUS
            LIMIT 1000;
            DBMS_OUTPUT.PUT_LINE('l_FISC_YEAR.COUNT'||chr(9)||l_FISC_YEAR.COUNT);
            FOR indx IN 1 .. l_FISC_YEAR.COUNT
        LOOP
          v_FISC_YEAR          := '20'||l_FISC_YEAR(indx);
          v_NTRPCLS_SGRP_CODE  := 'FY'||l_FISC_YEAR(indx);

          DBMS_OUTPUT.PUT_LINE('1: ACTIVITY_DATE'||chr(9)||v_ACTIVITY_DATE);

          DBMS_OUTPUT.PUT_LINE('2: v_FISC_YEAR'||chr(9)||v_FISC_YEAR);


          DBMS_OUTPUT.PUT_LINE ('l_FISC_YEAR'||chr(9)||l_FISC_YEAR(indx)||chr(9)||'v_FISC_YEAR'||chr(9)||v_FISC_YEAR||chr(9)||
          'l_BUDGET_ID'||chr(9)||l_BUDGET_ID(indx)||chr(9)||
          'l_BUDGET_PHASE'||chr(9)||l_BUDGET_PHASE(indx)||chr(9)||
          'l_BUDGET_STATUS'||chr(9)||l_BUDGET_STATUS(indx)||chr(9)||
          'v_ptrcaln_start_date'||chr(9)||v_ptrcaln_start_date||chr(9)||
          'v_POSN_EFFECTIVE_DATE'||chr(9)||v_POSN_EFFECTIVE_DATE||chr(9)||
          'v_eff_date'||chr(9)||v_eff_date||chr(9)||
          'v_nbrptot_budg_basis:'||chr(9)||v_nbrptot_budg_basis
          );
          SELECT TO_CHAR(v_POSN_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
          SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(v_POSN_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
          dbms_output.put_line('1: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);
          
        IF( (v_FISC_YEAR > v_extract_year  ) OR 
          ( (v_POSN_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693

              IF (l_BUDGET_STATUS(indx) = 'W') THEN
			  
					v_create_year := (TO_NUMBER(v_FISC_YEAR)) - 1;
					--HPSS-1693 10/14/2019
					SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(v_create_year)) )  ,  to_date ('2-SEP-'||TO_CHAR(v_create_year))
					into v_NBRPTOT_EFFECTIVE_DATE , v_working_cutoff_date FROM dual;
					
					DBMS_OUTPUT.PUT_LINE ('v_create_year: '||v_create_year||' l_FISC_YEAR('||indx||')'||l_FISC_YEAR(indx)||' v_working_cutoff_date: '||v_working_cutoff_date);
					
					IF(v_POSN_EFFECTIVE_DATE < v_working_cutoff_date) then
						v_NBRPTOT_EFFECTIVE_DATE := to_date ('1-SEP-'||TO_CHAR(v_working_cutoff_date, 'YYYY')) ; 
						DBMS_OUTPUT.PUT_LINE ('IF v_POSN_EFFECTIVE_DATE < v_working_cutoff_date ');
					else
						v_NBRPTOT_EFFECTIVE_DATE :=v_POSN_EFFECTIVE_DATE;
						DBMS_OUTPUT.PUT_LINE ('ELSE v_POSN_EFFECTIVE_DATE < v_working_cutoff_date ');
					end if;
					--HPSS-1693 10/14/2019
                dbms_output.put_line( 'testing: '||chr(10)||
                'indx: '||indx||'l_BUDGET_STATUS(indx): '||l_BUDGET_STATUS(indx)|| ' l_FISC_YEAR(indx): ' ||l_FISC_YEAR(indx) ||'v_NBRPTOT_EFFECTIVE_DATE: '||v_NBRPTOT_EFFECTIVE_DATE);
              ELSE   
                v_NBRPTOT_EFFECTIVE_DATE :=  v_POSN_EFFECTIVE_DATE;  
              END IF; 
              dbms_output.put_line( 'v_NBRPTOT_EFFECTIVE_DATE: '||v_NBRPTOT_EFFECTIVE_DATE );
			  
				DBMS_OUTPUT.PUT_LINE (v_nbbposn_posn||chr(9)|| v_FISC_YEAR||chr(9)|| v_NBRPTOT_EFFECTIVE_DATE||chr(9)|| v_POSN_FTE ||chr(9)||

				v_POSN_ORGN_CODE  ||chr(9)|| v_date||chr(9)|| v_nbrptot_budg_basis||chr(9)|| v_nbrptot_ann_basis||chr(9)||

				v_nbrptot_base_units||chr(9)|| v_nbrptot_appt_pct||chr(9)|| v_PTRECLS_CREATE_JFTE_IND||chr(9)||

				l_BUDGET_STATUS(indx)||chr(9)|| v_POSN_COAS_CODE||chr(9)|| v_NBRPTOT_BUDGET||chr(9)||

				null||chr(9)|| null||chr(9)|| l_BUDGET_ID(indx)||chr(9)|| l_BUDGET_PHASE(indx)||chr(9)||

				v_NTRPCLS_SGRP_CODE||chr(9)|| null||chr(9)|| null||chr(9)|| null||chr(9)||

				null||chr(9)|| null||chr(9)|| null||chr(9)|| null||chr(9)||

				null||chr(9)|| null||chr(9)|| null||chr(9)|| null||chr(9)||

				v_nbbposn_comment||chr(9)|| 'TT_HR_PASS'||chr(9)|| null||chr(9)|| null);
				
				
              
              INSERT INTO NBRPTOT
              (
              NBRPTOT_POSN, NBRPTOT_FISC_CODE, NBRPTOT_EFFECTIVE_DATE, NBRPTOT_FTE,
    
              NBRPTOT_ORGN_CODE, NBRPTOT_ACTIVITY_DATE, NBRPTOT_BUDG_BASIS, NBRPTOT_ANN_BASIS,
    
              NBRPTOT_BASE_UNITS, NBRPTOT_APPT_PCT, NBRPTOT_CREATE_JFTE_IND,
    
               NBRPTOT_STATUS, NBRPTOT_COAS_CODE, NBRPTOT_BUDGET,
    
              NBRPTOT_ENCUMB, NBRPTOT_EXPEND, NBRPTOT_OBUD_CODE, NBRPTOT_OBPH_CODE,
    
              NBRPTOT_SGRP_CODE, NBRPTOT_BUDGET_FRNG, NBRPTOT_ENCUMB_FRNG, NBRPTOT_EXPEND_FRNG,
    
              NBRPTOT_ACCI_CODE_FRNG, NBRPTOT_FUND_CODE_FRNG, NBRPTOT_ORGN_CODE_FRNG, NBRPTOT_ACCT_CODE_FRNG,
    
              NBRPTOT_PROG_CODE_FRNG, NBRPTOT_ACTV_CODE_FRNG, NBRPTOT_LOCN_CODE_FRNG, NBRPTOT_RECURRING_BUDGET,
    
              NBRPTOT_COMMENT, NBRPTOT_USER_ID, NBRPTOT_DATA_ORIGIN, NBRPTOT_VPDI_CODE
              )
              VALUES
              (
              v_nbbposn_posn, v_FISC_YEAR, v_NBRPTOT_EFFECTIVE_DATE, v_POSN_FTE ,
    
              v_POSN_ORGN_CODE  , v_date, v_nbrptot_budg_basis, v_nbrptot_ann_basis,
    
              v_nbrptot_base_units, v_nbrptot_appt_pct, v_PTRECLS_CREATE_JFTE_IND,
    
              l_BUDGET_STATUS(indx), v_POSN_COAS_CODE, v_NBRPTOT_BUDGET,
    
              null, null, l_BUDGET_ID(indx), l_BUDGET_PHASE(indx),
    
              v_NTRPCLS_SGRP_CODE, null, null, null,
    
              null, null, null, null,
    
              null, null, null, null,
    
              v_nbbposn_comment, 'TT_HR_PASS', null, null
              );

        END IF;   --HPSS-1693

       

        END LOOP;

  EXIT WHEN CURSOR_FISCYEAR%NOTFOUND;

  END LOOP;

CLOSE CURSOR_FISCYEAR;

        v_wstring := 'NBRPLBD_POSN'||chr(9)||'NBRPLBD_FISC_CODE'||chr(9)||'NBRPLBD_PERCENT'||chr(9)||'NBRPLBD_ACTIVITY_DATE'||chr(9)||

        'NBRPLBD_COAS_CODE'||chr(9)||'NBRPLBD_ACCI_CODE'||chr(9)||

        'NBRPLBD_FUND_CODE'||chr(9)||'NBRPLBD_ORGN_CODE'||chr(9)||'NBRPLBD_ACCT_CODE'||chr(9)||'NBRPLBD_PROG_CODE'||chr(9)||

        'NBRPLBD_ACTV_CODE'||chr(9)||'NBRPLBD_LOCN_CODE'||chr(9)||'NBRPLBD_ACCT_CODE_EXTERNAL'||chr(9)||'NBRPLBD_OBUD_CODE'||chr(9)||

        'NBRPLBD_OBPH_CODE'||chr(9)||'NBRPLBD_CHANGE_IND'||chr(9)||'NBRPLBD_PROJ_CODE'||chr(9)||'NBRPLBD_CTYP_CODE'||chr(9)||

        'NBRPLBD_BUDGET'||chr(9)||'NBRPLBD_BUDGET_TO_POST'||chr(9)||'NBRPLBD_USER_ID'||chr(9)||'NBRPLBD_DATA_ORIGIN'||chr(9)||

        'NBRPLBD_VPDI_CODE';
        
       DBMS_OUTPUT.PUT_LINE (v_wstring);


OPEN CURSOR_NBRPLBD_FISCYEAR(v_POSN_COAS_CODE, p_trans_no );
LOOP        --END LOOP;   -- OPEN CURSOR_NBRPLBD_FISCYEAR(v_POSN_COAS_CODE, p_trans_no );
            FETCH CURSOR_NBRPLBD_FISCYEAR
            BULK COLLECT INTO l_FISC_YEAR,
                              l_BUDGET_ID,
                              l_BUDGET_PHASE,
                              l_BUDGET_STATUS,
                              l_PASS_POSN_NBR,
                              l_PASS_COAS_CODE, 
                              l_PASS_FUND_CODE, 
                              l_PASS_ORGN_CODE,
                              
                              l_PASS_ACCT_CODE, 
            
                              l_PASS_POSN_PROG_CODE,                 
                              l_PASS_POSN_CURR_ACCT_PERC  
            LIMIT 1000;
            
            FOR indx IN 1 .. l_FISC_YEAR.COUNT       --END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
            
             
                                 
            LOOP        --END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
            
              v_FISC_YEAR := 20 ||l_FISC_YEAR(indx);
              
              v_NBRPLBD_BUDGET :=   ( (v_NBRPTOT_BUDGET * l_PASS_POSN_CURR_ACCT_PERC(indx) ) / 100);
              
              
              SELECT TO_CHAR(v_POSN_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
              SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(v_POSN_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
              dbms_output.put_line('1: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);
          
              IF( (v_FISC_YEAR > v_extract_year  ) OR 
              ( (v_POSN_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
              
                insert into NBRPLBD(
          
                NBRPLBD_POSN,  NBRPLBD_FISC_CODE, NBRPLBD_PERCENT,NBRPLBD_ACTIVITY_DATE,
    
                NBRPLBD_COAS_CODE, NBRPLBD_ACCI_CODE,
    
                NBRPLBD_FUND_CODE, NBRPLBD_ORGN_CODE, NBRPLBD_ACCT_CODE, NBRPLBD_PROG_CODE,
    
                NBRPLBD_ACTV_CODE, NBRPLBD_LOCN_CODE, NBRPLBD_ACCT_CODE_EXTERNAL, NBRPLBD_OBUD_CODE,
    
                NBRPLBD_OBPH_CODE,  NBRPLBD_CHANGE_IND, NBRPLBD_PROJ_CODE, NBRPLBD_CTYP_CODE,
    
                NBRPLBD_BUDGET, NBRPLBD_BUDGET_TO_POST, NBRPLBD_USER_ID, NBRPLBD_DATA_ORIGIN,
    
                NBRPLBD_VPDI_CODE)
                VALUES
                (
    
                l_PASS_POSN_NBR(indx), v_FISC_YEAR, l_PASS_POSN_CURR_ACCT_PERC(indx), v_date,
    
                l_PASS_COAS_CODE(indx), null,
    
                l_PASS_FUND_CODE(indx), l_PASS_ORGN_CODE(indx), l_PASS_ACCT_CODE(indx), l_PASS_POSN_PROG_CODE(indx),
    
                null, null, null, l_BUDGET_ID(indx),
    
                l_BUDGET_PHASE(indx),  null, null, null,
    
                v_NBRPLBD_BUDGET, 0, 'TT_HR_PASS', NULL,
    
                NULL
    
                );
                
                DBMS_OUTPUT.PUT_LINE (l_PASS_POSN_NBR(indx)||chr(9)||v_FISC_YEAR||chr(9)||l_PASS_POSN_CURR_ACCT_PERC(indx)||chr(9)||v_date||chr(9)||
      
                  l_PASS_COAS_CODE(indx)||chr(9)||null||chr(9)||
      
                  l_PASS_FUND_CODE(indx)||chr(9)||l_PASS_ORGN_CODE(indx)||chr(9)||l_PASS_ACCT_CODE(indx)||chr(9)||l_PASS_POSN_PROG_CODE(indx)||chr(9)||
      
                  null||chr(9)||null||chr(9)||null||chr(9)||l_BUDGET_ID(indx)||chr(9)||
      
                  l_BUDGET_PHASE(indx)||chr(9)||null||chr(9)||null||chr(9)||null||chr(9)||
      
                  v_NBRPLBD_BUDGET||chr(9)||NULL||chr(9)||'TT_HR_PASS'||chr(9)||NULL||chr(9)||
      
                  NULL);

              END IF; -- HPSS-1693
            
            
            END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
                
EXIT WHEN CURSOR_NBRPLBD_FISCYEAR%NOTFOUND;

END LOOP;   -- OPEN CURSOR_NBRPLBD_FISCYEAR(v_POSN_COAS_CODE, p_trans_no );

Update  TT_HR_PASS.NC_PASS_TRANS_B
set     TRANS_STATUS = 'U'  ,
        BNR_UPLOAD   = 'Y'
where TRANS_NO = p_trans_no;

COMMIT;

SELECT TRANS_STATUS, POSN_NBR
  INTO v_trans_holding_status, v_trans_holding_posn_nbr
  FROM TT_HR_PASS.NC_PASS_TRANS_B
 WHERE TRANS_NO = p_trans_no;


IF v_trans_holding_status = 'U' THEN
 P_UPDATE_EPM_PASS_STATUS(p_trans_no, v_trans_holding_posn_nbr, u_id, v_holding_status);
  
  IF v_holding_status = 'success' THEN
   rtn_flag := 'S'; --The Return Flag is Set to Success if the package is executed successfully
  ELSIF v_holding_status = 'empty' THEN
    rtn_flag := 'N'; --The Return Flag is Set to Not Success if the jv records are not submitted
  ELSE
    rtn_flag := 'E'; --The Return Flag is Set to Error if the package has an error
  END IF; 
END IF;

EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                       ROLLBACK TO s_pass_pbud_upd;
                       --The Return Flag is Set to E if the package experiences an error
                         rtn_flag := 'E';
                         err_msg := ('ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                         DBMS_OUTPUT.PUT_LINE(err_msg);                                
                        
                          insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','p_np_pbud_upd',
                          p_trans_no,u_id
                          );


                     END;

--1
END;

--------------------------------------------------------------------------------------------
-- OBJECT NAME: p_rc_banner_upd
-- PRODUCT....: HR
-- USAGE......: Update Banner tables and produce a report for the PASS Application 
--              based on the Reclassification Transaction
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--  This procedure will update a line into each one of the below mentioned tables  based on the Reclassification Transaction
-- 1) One line in NBBPOSN for the POSITION Number 
-- 2) One Line for each occurance of the Active Fiscal Year under NC_PASS_FISCYEAR_C Table in NBRPTOT
--     based on the Position Number
-- 3) One Line for each occurance of the Active Fiscal Year in NC_PASS_FISCYEAR_C Table in NBRPLBD
--     based on the Position Number
--------------------------------------------------------------------------------------------

PROCEDURE p_rc_banner_upd(pass_trans_no IN  varchar2,   u_id IN  varchar2, rtn_flag OUT varchar2) IS
wfile_handle                                                        utl_file.file_type;
v_one_up                                                            integer;
v_file                                                              varchar2 (300);
v_wstring                                                           varchar2 (6000);
v_eprint_user                                                       varchar2(90);
transfunding_rec                                                    TT_HR_PASS.NC_PASS_TRANSFUNDING_R%ROWTYPE;
v_ptrcaln_start_date                                                date;
v_eff_date                                                          date;
v_posn_ecls_code                                                    NBBPOSN.NBBPOSN_ECLS_CODE%TYPE;
v_FISC_YEAR                                                         varchar2(4);
v_COMMENT                                                           varchar2(2000);
v_date                                                              DATE;
v_new_nbbposn_auth_number                                               NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE;
v_NBRPTOT_BUDGET                                                    NUMBER(11,2);
v_NBRPTOT_ANN_BASIS                                                 NBRPTOT.NBRPTOT_ANN_BASIS%TYPE;
v_NBRPTOT_BUDG_BASIS                                                NBRPTOT.NBRPTOT_BUDG_BASIS%TYPE;
v_NBRPTOT_BASE_UNITS                                                NBRPTOT.NBRPTOT_BASE_UNITS%TYPE;
sql_stmt                                                            VARCHAR2(2500);
v_NBBPOSN_FLG                                                       VARCHAR2(1);
v_NBRPTOT_FLG                                                       VARCHAR2(1);
v_NBRPLBD_FLG                                                       VARCHAR2(1);
v_add_comment                                                       varchar2(2000);
v_trans_type                                                        VARCHAR2(2);
v_eff_date_char                                                     VARCHAR2(20);
v_date_char                                                         VARCHAR2(20);
v_NBBPOSN_PGRP_CODE                                                 NBBPOSN.NBBPOSN_PGRP_CODE%TYPE;
v_NTRPCLS_PGRP_CODE                                                 NTRPCLS.NTRPCLS_PGRP_CODE%TYPE;
v_nbrptot_appt_pct                                                  NBRPTOT.NBRPTOT_APPT_PCT%TYPE;
v_NTRPCLS_SGRP_CODE                                                 NTRPCLS.NTRPCLS_SGRP_CODE%TYPE;
v_extract_date                                                      varchar2(20);      --HPSS-1693
v_extract_year                                                      varchar2(20);      --HPSS-1693
v_working_cutoff_date                                               DATE;      --HPSS-1693
v_ep_flag                                                           varchar2(1);       --HPSS-1694
v_trans_status                                                       TT_HR_PASS.NC_PASS_TRANS_B.TRANS_STATUS%TYPE;
type r_FISC_YEAR                       IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.FISC_YEAR%TYPE;
type r_BUDGET_STATUS                   IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_STATUS%TYPE;
type r_BUDGET_ID                       IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_ID%TYPE;
type r_BUDGET_PHASE                    IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_PHASE%TYPE;

type r_PASS_POSN_NBR                   IS TABLE OF     TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE;
type r_PASS_COAS_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE;
type r_PASS_FUND_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_FUND_CODE%TYPE;
type r_PASS_ORGN_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_ORGN_CODE%TYPE;
type r_PASS_ACCT_CODE                  IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_ACCT_CODE%TYPE;

type r_PASS_POSN_PROG_CODE             IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_PROG_CODE%TYPE;
type r_PASS_POSN_CURR_ACCT_PERC        IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_CURRENT_ACCT_PERCENT%TYPE;
type r_PASS_POSN_PROP_ACCT_PERC        IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_PROPOSED_ACCT_PERCENT%TYPE;
type r_PASS_POSN_PROP_FOP_AMT        IS TABLE OF     TT_HR_PASS.NC_PASS_TRANSFUNDING_R.POSN_PROPOSED_ANNUAL_FOAP_AMT%TYPE;



l_FISC_YEAR                                                         r_FISC_YEAR;
l_BUDGET_STATUS                                                     r_BUDGET_STATUS;
l_BUDGET_ID                                                         r_BUDGET_ID;
l_BUDGET_PHASE                                                      r_BUDGET_PHASE;

l_PASS_POSN_NBR                   r_PASS_POSN_NBR;
l_PASS_COAS_CODE                  r_PASS_COAS_CODE;
l_PASS_FUND_CODE                  r_PASS_FUND_CODE;
l_PASS_ACCT_CODE                  r_PASS_ACCT_CODE;
l_PASS_ORGN_CODE                  r_PASS_ORGN_CODE;

l_PASS_POSN_PROG_CODE             r_PASS_POSN_PROG_CODE ;                 
l_PASS_POSN_CURR_ACCT_PERC        r_PASS_POSN_CURR_ACCT_PERC ;            
l_PASS_POSN_PROP_ACCT_PERC        r_PASS_POSN_PROP_ACCT_PERC ;
l_PASS_POSN_PROP_FOP_AMT        r_PASS_POSN_PROP_FOP_AMT ;
v_PLBD_Count                      Number;

TYPE trans_b_rec_typ IS RECORD (
      BO_APPROVER              TT_HR_PASS.NC_PASS_TRANS_B.BO_APPROVER%TYPE,
      
      PASS_POSN_NBR            TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE,
      
      PASS_APPROVAL_DATE       TT_HR_PASS.NC_PASS_TRANS_B.APPROVAL_DATE%TYPE,
      
      PASS_EFFECTIVE_DATE      TT_HR_PASS.NC_PASS_TRANS_B.POSN_EFFECTIVE_DATE%TYPE,

      PASS_TRANS_ID            TT_HR_PASS.NC_PASS_TRANS_B.TRANS_ID%TYPE,
      
      PASS_RATE_OF_PAY         TT_HR_PASS.NC_PASS_TRANS_B.POSN_RATE_OF_PAY%TYPE,
      
      PASS_FTE                 TT_HR_PASS.NC_PASS_TRANS_B.POSN_FTE%TYPE,
      
      PASS_COAS_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE, 

      PASS_ORGN_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_ORGN_CODE%TYPE,
      
      PASS_EXTENDED_TITLE      TT_HR_PASS.NC_PASS_TRANS_B.POSN_EXTENDED_TITLE%TYPE, 
      
      PASS_SINGLE_POOLED       TT_HR_PASS.NC_PASS_TRANS_B.POSN_SINGLE_POOLED%TYPE,
    
      PASS_PCLS_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_PCLS_CODE%TYPE,
      
      PASS_ECLS_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_ECLS_CODE%TYPE,
      
      PASS_PAY_GRADE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_PAY_GRADE%TYPE,
    
      PASS_FOC_CODE            TT_HR_PASS.NC_PASS_TRANS_B.POSN_FOC_CODE%TYPE,
      
      PASS_NTRPCLS_TABLE       NTRPCLS.NTRPCLS_TABLE%TYPE,
      
      PASS_EMPLOYEE_PIDM       TT_HR_PASS.NC_PASS_TRANS_B.EMPLOYEE_PIDM%TYPE, 
      
      PASS_VACANT_DATE         TT_HR_PASS.NC_PASS_TRANS_B.POSN_VACANT_BY_DATE%TYPE,
      
      PASS_FUTURE_VACANT       TT_HR_PASS.NC_PASS_TRANS_B.FUTURE_VACANT%TYPE,
      
      PASS_BNR_UPLOAD       TT_HR_PASS.NC_PASS_TRANS_B.BNR_UPLOAD%TYPE   

      );

trans_b_rec trans_b_rec_typ;

v_PTRECLS_PICT_CODE                    PTRECLS.PTRECLS_PICT_CODE%TYPE;
v_PTRECLS_INTERNAL_FT_PT_IND           PTRECLS.PTRECLS_INTERNAL_FT_PT_IND%TYPE; 
v_PTRECLS_BUDG_BASIS                   PTRECLS.PTRECLS_BUDG_BASIS%TYPE;
v_PTRECLS_ANN_BASIS                    PTRECLS.PTRECLS_ANN_BASIS%TYPE;
v_PTRECLS_CREATE_JFTE_IND              PTRECLS.PTRECLS_CREATE_JFTE_IND%TYPE;
v_NBBPOSN_TITLE                        NBBPOSN.NBBPOSN_TITLE%TYPE; 
v_NBBPOSN_TYPE                         NBBPOSN.NBBPOSN_TITLE%TYPE; 
v_NBBPOSN_PCLS_CODE                    NBBPOSN.NBBPOSN_PCLS_CODE%TYPE;  
v_NBBPOSN_ECLS_CODE                    NBBPOSN.NBBPOSN_ECLS_CODE%TYPE; 
v_NBBPOSN_GRADE                        NBBPOSN.NBBPOSN_GRADE%TYPE; 
v_NBBPOSN_COAS_CODE                    NBBPOSN.NBBPOSN_COAS_CODE%TYPE; 
v_NBBPOSN_TABLE                        NBBPOSN.NBBPOSN_TABLE%TYPE; 
v_NBBPOSN_COMMENT                      NBBPOSN.NBBPOSN_COMMENT%TYPE; 
v_NBBPOSN_PFOC_CODE                    NBBPOSN.NBBPOSN_PFOC_CODE%TYPE;  
v_NBBPOSN_AUTH_NUMBER                  NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE; 
v_NBRPLBD_BUDGET                       NBRPLBD.NBRPLBD_BUDGET%TYPE; 
v_PTOT_BDG_CNT                         NUMBER;       
v_PTOT_TRANS_BDG                       NBRPTOT.NBRPTOT_BUDGET%TYPE;
v_PTOT_APP_BDG                         NBRPTOT.NBRPTOT_BUDGET%TYPE;
v_NBRPTOT_COMMENT                      NBRPTOT.NBRPTOT_COMMENT%TYPE;
v_DEL_PLBD_CMT                         NUMBER;
v_NBRPTOT_COMMENT_CNT                  NUMBER;
v_SPRIDEN_COUNT                        NUMBER;
v_NBRPTOT_EFFECTIVE_DATE               NBRPTOT.NBRPTOT_EFFECTIVE_DATE%TYPE;

TYPE NbrptotRecTyp IS RECORD (
        obud_code             NBRPTOT.NBRPTOT_OBUD_CODE%TYPE,
        ptot_fisc_code        NBRPTOT.NBRPTOT_FISC_CODE%TYPE,
        ptot_fte              NBRPTOT.NBRPTOT_FTE%TYPE, 
        ptot_coas_code        NBRPTOT.NBRPTOT_COAS_CODE%TYPE,
        ptot_orgn_code        NBRPTOT.NBRPTOT_ORGN_CODE%TYPE, 
        ptot_budget           NBRPTOT.NBRPTOT_BUDGET%TYPE,
        ptot_budg_basis       NBRPTOT.NBRPTOT_BUDG_BASIS%TYPE,
        ptot_ann_basis        NBRPTOT.NBRPTOT_ANN_BASIS%TYPE,
        
        ptot_base_units       NBRPTOT.NBRPTOT_BASE_UNITS%TYPE,
        ptot_comment          NBRPTOT.NBRPTOT_COMMENT%TYPE
);
Nbrptot_rec1  NbrptotRecTyp; 

TYPE NbrplbdRecTyp IS RECORD (
bnr_plbd_fund_code            NBRPLBD.NBRPLBD_FUND_CODE%TYPE, 
bnr_plbd_orgn_code            NBRPLBD.NBRPLBD_ORGN_CODE%TYPE, 
bnr_plbd_acct_code            NBRPLBD.NBRPLBD_ACCT_CODE%TYPE, 
bnr_plbd_prog_code            NBRPLBD.NBRPLBD_PROG_CODE%TYPE,
bnr_plbd_percent              NBRPLBD.NBRPLBD_PERCENT%TYPE, 
bnr_plbd_budget               NBRPLBD.NBRPLBD_BUDGET%TYPE
);
Nbrplbd_rec1  NbrplbdRecTyp;

v_holding_status varchar2(8);
v_trans_holding_posn_nbr varchar2(6);
v_trans_holding_status varchar2(2);
v_EMP_RID                     SATURN.SPRIDEN.SPRIDEN_ID%TYPE;
v_EMP_FIRST_NAME              SATURN.SPRIDEN.SPRIDEN_FIRST_NAME%TYPE;
v_EMP_LAST_NAME               SATURN.SPRIDEN.SPRIDEN_LAST_NAME%TYPE;
v_PASS_BUDGET                 tt_hr_pass.nc_pass_transfunding_R.POSN_PROPOSED_ANNUAL_FOAP_AMT%TYPE;
v_TOT_BUDGET                  NBRPTOT.NBRPTOT_BUDGET%TYPE; 
v_plbd_cnt                    number;  
v_NEW_PLBD_CMT                number;
v_curr_pec                    tt_hr_pass.nc_pass_transfunding_R.POSN_CURRENT_ACCT_PERCENT%TYPE;
v_create_year                 number;
type r_COMMENT_DESC                       IS TABLE OF     tt_hr_pass.nc_pass_comments_r.COMMENT_DESC%TYPE;  --HPSS-1666
l_COMMENT_DESC                    r_COMMENT_DESC; --HPSS-1666


--CURSOR USED TO RETURN PASS FISC YEAR THERE CAN BE MULTIPLE ACTIVE FISCAL YEARS
CURSOR CURSOR_FISCYEAR (chart IN varchar2) IS
  select FISC_YEAR, BUDG_ID, BUDG_PHASE, BUDG_STATUS
  from tt_hr_pass.nc_pass_fiscyear_c
  where coas_code = chart
  and Status = 'A'; 
  
-- THIS CURSOR IS USED TO FETCH THE VALUES FROM NBRPTOT TABLE  
CURSOR CURSOR_NBRPTOT (p_posn IN varchar2, p_fisc_code IN varchar2) IS
select  

NBRPTOT_OBUD_CODE, NBRPTOT_FISC_CODE,

NBRPTOT_FTE, NBRPTOT_COAS_CODE,

NBRPTOT_ORGN_CODE, NBRPTOT_BUDGET,

NBRPTOT_BUDG_BASIS, NBRPTOT_ANN_BASIS,

NBRPTOT_BASE_UNITS, NBRPTOT_COMMENT

FROM NBRPTOT
--FOR ONE POSITION NBRPTOT HAS ONLY ONE 'A' APPROVED RECORD FOR THAT FISCAL YEAR
WHERE 
NBRPTOT_POSN = p_posn
AND NBRPTOT_FISC_CODE = p_fisc_code
AND NBRPTOT_STATUS in ('A','W')
;

CURSOR CURSOR_NBRPLBD_FISCYEAR (p_chart IN varchar2, p_trans_no IN varchar2) IS 
select fisc.FISC_YEAR, fisc.BUDG_ID, fisc.BUDG_PHASE, fisc.BUDG_STATUS, trans_b.POSN_NBR, trans_b.POSN_COAS_CODE,  trans_f.POSN_FUND_CODE, trans_f.POSN_ORGN_CODE,
trans_f.POSN_ACCT_CODE,  trans_f.POSN_PROG_CODE,  trans_f.POSN_CURRENT_ACCT_PERCENT,   trans_f.POSN_PROPOSED_ACCT_PERCENT  , trans_f.POSN_PROPOSED_ANNUAL_FOAP_AMT
from tt_hr_pass.nc_pass_fiscyear_c fisc, tt_hr_pass.nc_pass_trans_b trans_b, tt_hr_pass.nc_pass_transfunding_r trans_f 
where 
fisc.coas_code = p_chart AND  
fisc.Status = 'A'and 
trans_b.trans_no = p_trans_no  
and trans_f.NC_PASS_TRANS_B_ID =  trans_b.TRANS_ID; 

cursor CURSOR_DEL_PLBD(chart IN varchar2) IS
  select FISC_YEAR
  from tt_hr_pass.nc_pass_fiscyear_c
  where coas_code = chart
  and Status = 'A'; 
--HPSS-1666  
CURSOR Chart_E_Budget_Comments(p_trans_id IN NUMBER) IS
SELECT COMMENT_DESC from tt_hr_pass.nc_pass_comments_r 
where AREA = 'budget' and NC_PASS_TRANS_B_ID = p_trans_id  and user_id <> 'NPR System'
ORDER BY ACTIVITY_DATE desc;  
--HPSS-1666    
begin

        savepoint s_pass_update_banner;
 
        v_file := 'p_pass_banner_update.xls';
        wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');
        
        v_wstring := 'TRANSACTION TYPE'||chr(9)||'RECLASS';
        utl_file.put_line(wfile_handle,v_wstring);
        
        DBMS_OUTPUT.PUT_LINE (v_wstring);

        v_wstring := 'TRANSACTION NUMBER'||chr(9)||pass_trans_no;
        utl_file.put_line(wfile_handle,v_wstring);

        DBMS_OUTPUT.PUT_LINE (v_wstring);

        select sysdate into v_date from dual;
          
        
        --1. Open NC_PASS_TRANS_B Record    
        
        SELECT trans_b_1.BO_APPROVER, trans_b_1.POSN_NBR, trans_b_1.APPROVAL_DATE, trans_b_1.POSN_EFFECTIVE_DATE, 

        trans_b_1.TRANS_ID, trans_b_1.POSN_RATE_OF_PAY, trans_b_1.POSN_FTE, trans_b_1.POSN_COAS_CODE, 

        trans_b_1.POSN_ORGN_CODE, trans_b_1.POSN_EXTENDED_TITLE, trans_b_1.POSN_SINGLE_POOLED,
        
        trans_b_1.POSN_PCLS_CODE, trans_b_1.POSN_ECLS_CODE, trans_b_1.POSN_PAY_GRADE,
        
        trans_b_1.POSN_FOC_CODE ,  rpcls.NTRPCLS_TABLE,  trans_b_1.EMPLOYEE_PIDM,
        
        trans_b_1.POSN_VACANT_BY_DATE , trans_b_1.FUTURE_VACANT, trans_b_1.BNR_UPLOAD 
        
        into    trans_b_rec

        FROM  TT_HR_PASS.NC_PASS_TRANS_B trans_b_1, NTRPCLS rpcls
        WHERE  trans_b_1.TRANS_NO = pass_trans_no
        and trans_b_1.POSN_PCLS_CODE = rpcls.NTRPCLS_CODE
        AND trans_b_1.TRANS_STATUS IN ('S','C') AND BNR_UPLOAD IS NULL ;
        
        DBMS_OUTPUT.PUT_LINE (chr(10)||'trans_b_rec.PASS_ECLS_CODE: '||trans_b_rec.PASS_ECLS_CODE||chr(10));
        
        select count(*) 
        INTO v_SPRIDEN_COUNT               
        from saturn.spriden where spriden_pidm = trans_b_rec.PASS_EMPLOYEE_PIDM 
        and spriden_change_ind is null;
        
        IF (v_SPRIDEN_COUNT > 0) THEN
            select SPRIDEN_ID, SPRIDEN_FIRST_NAME, SPRIDEN_LAST_NAME
            INTO v_EMP_RID, v_EMP_FIRST_NAME, v_EMP_LAST_NAME
            from saturn.spriden where spriden_pidm = trans_b_rec.PASS_EMPLOYEE_PIDM
            and spriden_change_ind is null;
        END IF;  

       SELECT PTRECLS_PICT_CODE, PTRECLS_INTERNAL_FT_PT_IND, 
       PTRECLS_BUDG_BASIS, PTRECLS_ANN_BASIS  , PTRECLS_CREATE_JFTE_IND
       INTO v_PTRECLS_PICT_CODE, v_PTRECLS_INTERNAL_FT_PT_IND, 
       v_PTRECLS_BUDG_BASIS, v_PTRECLS_ANN_BASIS , v_PTRECLS_CREATE_JFTE_IND
       
       FROM PTRECLS
       WHERE PTRECLS_CODE = trans_b_rec.PASS_ECLS_CODE;  
     
        DBMS_OUTPUT.PUT_LINE (chr(10)||
                                  'PTRECLS_PICT_CODE: '||v_PTRECLS_PICT_CODE||chr(10)||
                                  'PTRECLS_INTERNAL_FT_PT_IND: '||v_PTRECLS_INTERNAL_FT_PT_IND||chr(10)||
                                  'PTRECLS_BUDG_BASIS: '||v_PTRECLS_BUDG_BASIS||chr(10)||
                                  'PTRECLS_ANN_BASIS: '||v_PTRECLS_ANN_BASIS||chr(10)||
                                  'EMP DETAILS'||v_EMP_RID||' '||v_EMP_FIRST_NAME||' '||v_EMP_LAST_NAME 
                                  );    
                                  
        --1.3. CALCULATE EFFECTIVE DATE
        
        IF (trans_b_rec.PASS_VACANT_DATE IS NOT NULL) THEN
        v_eff_date :=   trans_b_rec.PASS_VACANT_DATE;
        DBMS_OUTPUT.PUT_LINE (chr(10)||
                                  'v_eff_date: '||v_eff_date||chr(10)||
                                  'trans_b_rec.PASS_VACANT_DATE: '||trans_b_rec.PASS_VACANT_DATE||chr(10) );  
        ELSIF (trans_b_rec.PASS_EMPLOYEE_PIDM IS NULL) THEN
        v_eff_date :=   v_date;
        DBMS_OUTPUT.PUT_LINE (chr(10)||
                                  'v_eff_date: '||v_eff_date||chr(10)||
                                  'trans_b_rec.PASS_EMPLOYEE_PIDM: '|| trans_b_rec.PASS_EMPLOYEE_PIDM ||chr(10) ); 
        ELSE                          
        v_eff_date  :=  getCalcEffDate(v_PTRECLS_PICT_CODE, v_date, trans_b_rec.PASS_EFFECTIVE_DATE);
        DBMS_OUTPUT.PUT_LINE (chr(10)||
                                  'v_eff_date: '||v_eff_date||chr(10)||
                                  'trans_b_rec.PASS_VACANT_DATE: '||trans_b_rec.PASS_VACANT_DATE||chr(10)||
                                  'trans_b_rec.PASS_EMPLOYEE_PIDM: '|| trans_b_rec.PASS_EMPLOYEE_PIDM ||chr(10) ); 
                                    
        END IF;
   
        --inserting calculated effective date into TT_HR_PASS.NC_PASS_TRANS_B
        UPDATE TT_HR_PASS.NC_PASS_TRANS_B
        SET CALC_EFF_DATE =  v_eff_date
        WHERE TRANS_NO = pass_trans_no; 
        
        --2. Open NBBPOSN Record
        
        select 
        bposn.NBBPOSN_TITLE, bposn.NBBPOSN_TYPE, 

        bposn.NBBPOSN_PCLS_CODE, bposn.NBBPOSN_ECLS_CODE, 

        bposn.NBBPOSN_GRADE, bposn.NBBPOSN_COAS_CODE, 

        bposn.NBBPOSN_TABLE,  bposn.NBBPOSN_COMMENT,

        bposn.NBBPOSN_PFOC_CODE, bposn.NBBPOSN_AUTH_NUMBER,
        
        bposn.NBBPOSN_PGRP_CODE, rpcls.NTRPCLS_PGRP_CODE,
        
        rpcls.NTRPCLS_SGRP_CODE        
        
        into 
        
        v_NBBPOSN_TITLE, v_NBBPOSN_TYPE, 

        v_NBBPOSN_PCLS_CODE, v_NBBPOSN_ECLS_CODE, 

        v_NBBPOSN_GRADE, v_NBBPOSN_COAS_CODE, 

        v_NBBPOSN_TABLE,  v_NBBPOSN_COMMENT,

        v_NBBPOSN_PFOC_CODE, v_NBBPOSN_AUTH_NUMBER,
        
        v_NBBPOSN_PGRP_CODE, v_NTRPCLS_PGRP_CODE,
        
        v_NTRPCLS_SGRP_CODE

        FROM NBBPOSN bposn, NTRPCLS rpcls
        WHERE  bposn.NBBPOSN_POSN = trans_b_rec.PASS_POSN_NBR    --nbbposn_posn is the primary key
        AND bposn.nbbposn_pcls_code = rpcls.ntrpcls_code;  
        
        v_trans_type := SUBSTR(pass_trans_no, 1, 2);
        dbms_output.put_line('v_trans_type: '||v_trans_type);
        
        v_ep_flag := getElPasoRCFlag(pass_trans_no,  trans_b_rec.PASS_COAS_CODE, trans_b_rec.PASS_EMPLOYEE_PIDM, trans_b_rec.PASS_FUTURE_VACANT, trans_b_rec.PASS_APPROVAL_DATE,
        trans_b_rec.PASS_BNR_UPLOAD, v_eff_date );
                
        dbms_output.put_line('v_NBBPOSN_PGRP_CODE: '||v_NBBPOSN_PGRP_CODE||'v_NTRPCLS_PGRP_CODE: '||v_NTRPCLS_PGRP_CODE||' V_EP_FLAG: '||v_ep_flag);
      
        --For Reclass
        --If the calculated Effective Date is less than the system date update the Position and create an EPAF
        --For Salary Review, Update position irrespective of the Effective Date
        IF ( ( (v_trans_type ='RC') OR (v_trans_type ='SR') ) AND (v_ep_flag = 'N') )THEN   --  END IF;    --   IF ( ( (v_trans_type ='RC') OR (v_trans_type ='SR') ) AND (v_ep_flag = 'N') )THEN
        
        v_comment  := NULL;
        --Get NEW NBBPOSN AUTH CODE
        IF (trans_b_rec.BO_APPROVER = 'PASS') THEN
        v_new_nbbposn_auth_number   :=  'PASS';
        ELSE
        v_new_nbbposn_auth_number   :=  'PASS '||nvl(trans_b_rec.BO_APPROVER, '');
        END IF;
        
        dbms_output.put_line('v_new_nbbposn_auth_number: '||v_new_nbbposn_auth_number);
        
        sql_stmt := 'UPDATE NBBPOSN SET NBBPOSN_AUTH_NUMBER = '''|| v_new_nbbposn_auth_number ||''''; 
        v_add_comment := 'NBBPOSN AUTH NUMBER updated by PASS from '||v_NBBPOSN_AUTH_NUMBER||' TO '||v_new_nbbposn_auth_number||' ON '||v_date;
        v_comment     := fstringConcat(v_comment, v_add_comment);
        
        
        --update NBBPOSN IF there are changes
                 
            IF (trans_b_rec.PASS_EXTENDED_TITLE != v_NBBPOSN_TITLE) then

                
                    sql_stmt := sql_stmt||' , NBBPOSN_TITLE = '''|| trans_b_rec.PASS_EXTENDED_TITLE ||'''';
                
                    v_add_comment := 'NBBPOSN TITLE updated by PASS from '||v_NBBPOSN_TITLE||' TO '||trans_b_rec.PASS_EXTENDED_TITLE||' ON '||v_date;
                
                    v_comment := fstringConcat(v_comment, v_add_comment);
                
            end if;
            

            IF (trans_b_rec.PASS_PCLS_CODE != v_NBBPOSN_PCLS_CODE) then

                 
                  sql_stmt := sql_stmt||' , NBBPOSN_PCLS_CODE = '''||trans_b_rec.PASS_PCLS_CODE ||'''';
                  
                  v_add_comment := 'NBBPOSN PCLS CODE updated by PASS  from '||v_NBBPOSN_PCLS_CODE||' TO '||trans_b_rec.PASS_PCLS_CODE||' ON '||v_date;
                  
                  v_comment := fstringConcat(v_comment, v_add_comment);
                
            end if;   
            
            IF (trans_b_rec.PASS_ECLS_CODE != v_NBBPOSN_ECLS_CODE) then
                 
                 sql_stmt := sql_stmt||' , NBBPOSN_ECLS_CODE = '''||trans_b_rec.PASS_ECLS_CODE||'''';
                 
                 v_add_comment := 'NBBPOSN ECLS CODE  updated  by PASS from'||v_NBBPOSN_ECLS_CODE||' TO '||trans_b_rec.PASS_ECLS_CODE||' ON '||v_date;
                 v_comment := fstringConcat(v_comment, v_add_comment);
                
            end if;          
            
            IF (trans_b_rec.PASS_NTRPCLS_TABLE != v_NBBPOSN_TABLE) then
                 
                 sql_stmt := sql_stmt||' , NBBPOSN_TABLE = '''||trans_b_rec.PASS_NTRPCLS_TABLE||'''';
                 
                 v_add_comment := 'NTRPCLS TABLE updated by PASS  from '||v_NBBPOSN_TABLE||' TO '||trans_b_rec.PASS_NTRPCLS_TABLE||' ON '||v_date;
                 v_comment := fstringConcat(v_comment, v_add_comment);
                
            end if; 
            
            IF (trans_b_rec.PASS_PAY_GRADE != v_NBBPOSN_GRADE) then
                 
                 sql_stmt := sql_stmt||' , NBBPOSN_GRADE = '''||trans_b_rec.PASS_PAY_GRADE||'''';
                 
                 v_add_comment := 'NBBPOSN PAY GRADE updated by PASS from '||v_NBBPOSN_GRADE||' TO '||trans_b_rec.PASS_PAY_GRADE||' ON '||v_date;
                 v_comment := fstringConcat(v_comment, v_add_comment);
                
            end if; 
            
            IF ( (trans_b_rec.PASS_FOC_CODE IS NOT NULL) and (v_NBBPOSN_PFOC_CODE is not null) )   then
            
                 IF(trans_b_rec.PASS_FOC_CODE != v_NBBPOSN_PFOC_CODE) then
                 
                    sql_stmt := sql_stmt||' , NBBPOSN_PFOC_CODE = '''||trans_b_rec.PASS_FOC_CODE||'''';
                 
                    v_add_comment := 'NBBPOSN PFOC CODE updated by PASS from '||v_NBBPOSN_PFOC_CODE||' TO '||trans_b_rec.PASS_FOC_CODE||' ON '||v_date;
                    v_comment := fstringConcat(v_comment, v_add_comment);
                 END IF; 
                
            END IF; 
            
            IF ( (trans_b_rec.PASS_FOC_CODE IS NULL) and (v_NBBPOSN_PFOC_CODE is not null) ) then
                 
                    sql_stmt := sql_stmt||' , NBBPOSN_PFOC_CODE = '''||trans_b_rec.PASS_FOC_CODE||'''';
                 
                    v_add_comment := 'NBBPOSN PFOC CODE updated by PASS from '||v_NBBPOSN_PFOC_CODE||' TO '||trans_b_rec.PASS_FOC_CODE||' ON '||v_date;
                    v_comment := fstringConcat(v_comment, v_add_comment);

                
            END IF; 
            
            IF ( (trans_b_rec.PASS_FOC_CODE IS NOT  NULL) and (v_NBBPOSN_PFOC_CODE is null) )    then
                
                    sql_stmt := sql_stmt||' , NBBPOSN_PFOC_CODE = '''||trans_b_rec.PASS_FOC_CODE||'''';
                 
                    v_add_comment := 'NBBPOSN PFOC CODE updated by PASS from '||v_NBBPOSN_PFOC_CODE||' TO '||trans_b_rec.PASS_FOC_CODE||' ON '||v_date;
                    v_comment := fstringConcat(v_comment, v_add_comment);

                
            END IF; 
            
            IF (v_NBBPOSN_PGRP_CODE != v_NTRPCLS_PGRP_CODE) then
                 
                 sql_stmt := sql_stmt||' , NBBPOSN_PGRP_CODE = '''||v_NTRPCLS_PGRP_CODE||'''';
                 
                 v_add_comment := 'NBBPOSN PGRP CODE updated by PASS  from '||v_NBBPOSN_PGRP_CODE||' TO '||v_NTRPCLS_PGRP_CODE||' ON '||v_date;
                 v_comment := fstringConcat(v_comment, v_add_comment);
                
            end if;
            
            --IF(v_NBBPOSN_FLG = 'Y') then
            
                 utl_file.put_line(wfile_handle,v_comment);
                 --v_comment  := 'NBBPOSN_COMMENT changed to '||v_comment;
                 v_comment := fstringConcat(v_NBBPOSN_COMMENT, v_comment);
                 v_comment := REPLACE(v_comment,'''', ''''' ');
                 sql_stmt := sql_stmt ||' , '||' NBBPOSN_USER_ID = ''TT_HR_PASS''' ||
                 ' , '||' NBBPOSN_ACTIVITY_DATE = '''||v_date||'''' ||
                 ' , '||' NBBPOSN_CHANGE_DATE_TIME = '''||v_date||'''' ||
                 ' , '||' NBBPOSN_COMMENT = '''||v_comment||''' WHERE NBBPOSN_POSN = '''||trans_b_rec.PASS_POSN_NBR||'''';
                 
                 DBMS_OUTPUT.PUT_LINE (v_comment||chr(10)||'Query'||chr(10) ||sql_stmt);
                 
                 EXECUTE IMMEDIATE sql_stmt;
     
          --end if;
            
        /*Calculate
                1.v_NBRPTOT_BUDGET
                2.v_NBRPTOT_BASE_UNITS
                3.v_NBRPTOT_ANN_BASIS
                4.v_NBRPTOT_BUDG_BASIS
        */
          
              IF(v_PTRECLS_PICT_CODE = 'MN') THEN
               
               v_NBRPTOT_BUDGET     := trans_b_rec.PASS_RATE_OF_PAY;
               v_NBRPTOT_BASE_UNITS := 12;
               v_nbrptot_appt_pct   :=  100;
                
              ELSIF(v_PTRECLS_PICT_CODE = 'SM') THEN
              
                v_NBRPTOT_BUDGET     := trans_b_rec.PASS_FTE * trans_b_rec.PASS_RATE_OF_PAY *2080.08;
                v_NBRPTOT_BASE_UNITS := 24;
                v_nbrptot_appt_pct   :=  100; 
              ELSIF(v_PTRECLS_PICT_CODE = 'NS') THEN  
                v_nbrptot_appt_pct   := 0; 
  
                
              END IF;
          
              IF(trans_b_rec.PASS_FTE = 0)       THEN
                
                    v_NBRPTOT_ANN_BASIS  := 0;
                    v_NBRPTOT_BASE_UNITS := 0;
              ELSE
                    v_NBRPTOT_ANN_BASIS := v_PTRECLS_BUDG_BASIS;                
              END IF;
          
                v_NBRPTOT_BUDG_BASIS := trans_b_rec.PASS_FTE * v_NBRPTOT_ANN_BASIS;
                
          DBMS_OUTPUT.PUT_LINE (chr(10)||'v_NBRPTOT_ANN_BASIS: '||chr(9)||v_NBRPTOT_ANN_BASIS||chr(9)||' v_NBRPTOT_BUDG_BASIS: '||chr(9)||v_NBRPTOT_BUDG_BASIS||chr(10)||
          'PICT_CODE: '||chr(9)||v_PTRECLS_PICT_CODE||chr(9)||' v_NBRPTOT_BUDGET: '||chr(9)||v_NBRPTOT_BUDGET||chr(10)||
          'PASS_FTE: '||chr(9)||trans_b_rec.PASS_FTE||chr(9)||' PTRECLS_ANN_BASIS: '||chr(9)||v_PTRECLS_ANN_BASIS||chr(10));
          
          select to_char(trans_b_rec.PASS_EFFECTIVE_DATE,'MM.DD.YYYY'),  to_char(v_date,'MM.DD.YYYY')
          into v_eff_date_char, v_date_char from dual;
		  if trans_b_rec.PASS_COAS_CODE = 'E' then
			--HPSS-1666
			v_comment := NULL;
			OPEN Chart_E_Budget_Comments(trans_b_rec.PASS_TRANS_ID);
			LOOP 
				FETCH Chart_E_Budget_Comments BULK COLLECT INTO l_COMMENT_DESC
				LIMIT 1000;
					FOR budg_indx IN 1 .. l_COMMENT_DESC.COUNT
					LOOP
						DBMS_OUTPUT.PUT_LINE ('l_COMMENT_DESC('||budg_indx||'): '||l_COMMENT_DESC(budg_indx));
						IF (v_comment IS NULL ) THEN
							v_comment := l_COMMENT_DESC(budg_indx);
							DBMS_OUTPUT.PUT_LINE ('IF: '||v_comment);
						ELSE
							v_comment := v_comment||chr(10)||l_COMMENT_DESC(budg_indx);
							DBMS_OUTPUT.PUT_LINE ('ELSE: '||v_comment);
						END IF;
					END LOOP;		

			EXIT WHEN Chart_E_Budget_Comments%NOTFOUND;
			END LOOP;
			CLOSE Chart_E_Budget_Comments;	
			--HPSS-1666
			 /*SELECT LISTAGG(COMMENT_DESC, ' ') WITHIN GROUP (ORDER BY ACTIVITY_DATE desc) into v_comment
			 from tt_hr_pass.nc_pass_comments_R where AREA = 'budget' and NC_PASS_TRANS_B_ID = trans_b_rec.PASS_TRANS_ID and user_id <> 'NPR System';*/
		  else
			v_comment := null; --v_date_char||' PASS '||pass_trans_no||' with Eff Date '||v_eff_date_char||' '||v_EMP_RID||' '||v_EMP_FIRST_NAME||', '||v_EMP_LAST_NAME||' Updated ';
		  end if;   
          DBMS_OUTPUT.PUT_LINE ('HPSS-1666: v_comment: '||v_comment);
		  
		  
           OPEN CURSOR_FISCYEAR(trans_b_rec.PASS_COAS_CODE);

                LOOP
                FETCH CURSOR_FISCYEAR
                BULK COLLECT INTO l_FISC_YEAR,
                                  l_BUDGET_ID,
                                  l_BUDGET_PHASE,
                                  l_BUDGET_STATUS
                LIMIT 1000;
                DBMS_OUTPUT.PUT_LINE('l_FISC_YEAR.COUNT'||chr(9)||l_FISC_YEAR.COUNT);
                    FOR indx IN 1 .. l_FISC_YEAR.COUNT
                          LOOP
                          DBMS_OUTPUT.PUT_LINE (chr(10)||'l_FISC_YEAR'||chr(9)||l_FISC_YEAR(indx)||chr(9)||
                              'l_BUDGET_ID'||chr(9)||l_BUDGET_ID(indx)||chr(9)||
                              'l_BUDGET_PHASE'||chr(9)||l_BUDGET_PHASE(indx)||chr(9)||
                              'l_BUDGET_STATUS'||chr(9)||l_BUDGET_STATUS(indx)||chr(9)||
                              'v_ptrcaln_start_date'||chr(9)||v_ptrcaln_start_date||chr(9)||
                              'trans_b_rec.PASS_EFFECTIVE_DATE'||chr(9)||trans_b_rec.PASS_EFFECTIVE_DATE||chr(9)||
                              'v_eff_date'||chr(9)||v_eff_date||chr(10)
                              );
                          v_FISC_YEAR := 20 ||l_FISC_YEAR(indx);
                          
                          
                          DBMS_OUTPUT.PUT_LINE (chr(10)||
                          ' CURSOR_NBRPTOT PARAMETERS: '||chr(10)||
                              'trans_b_rec.PASS_POSN_NBR: '||trans_b_rec.PASS_POSN_NBR||chr(10)||
                              'v_FISC_YEAR: '||v_FISC_YEAR||chr(10)||
                              'pass_trans_no: '||pass_trans_no||chr(10)
                              );
                              
                              
                               
                               SELECT SUM(NBRPTOT_BUDGET)  INTO  v_PTOT_TRANS_BDG
                               FROM NBRPTOT
                               WHERE
                               NBRPTOT_POSN          = trans_b_rec.PASS_POSN_NBR
                               AND NBRPTOT_FISC_CODE =  v_FISC_YEAR
                               AND NBRPTOT_STATUS    =  'T' ;  
                               
                                                           
                               OPEN CURSOR_NBRPTOT (trans_b_rec.PASS_POSN_NBR, v_FISC_YEAR);
                               LOOP                      
                               FETCH CURSOR_NBRPTOT  into Nbrptot_rec1;
                               
                                    if(Nbrptot_rec1.ptot_fisc_code is null ) then     -- end if;  --if(Nbrptot_rec1.ptot_fisc_code is null ) then
                                    
                                              v_NTRPCLS_SGRP_CODE  := 'FY'||l_FISC_YEAR(indx);
                                              v_nbbposn_comment := 'PASS '||pass_trans_no||' with effective date '||trans_b_rec.PASS_EFFECTIVE_DATE||' inserted this record' ;
                                              --v_comment := ' '||v_FISC_YEAR;
											  IF trans_b_rec.PASS_COAS_CODE != 'E' then
												v_nbbposn_comment  := v_comment;  -- HPSS-1666
											  END IF;
                                              utl_file.put_line(wfile_handle,v_comment);                            
                                              DBMS_OUTPUT.PUT_LINE ('NBRPTOT record does not exist for the year '||v_FISC_YEAR||chr(10)||
                                              'trans_b_rec.PASS_POSN_NBR: '||trans_b_rec.PASS_POSN_NBR||
                                              'v_FISC_YEAR: '|| v_FISC_YEAR||
                                              'trans_b_rec.PASS_EFFECTIVE_DATE: '|| trans_b_rec.PASS_EFFECTIVE_DATE||
                                              'trans_b_rec.POSN_FTE: '|| trans_b_rec.PASS_FTE||
                                              'trans_b_rec.POSN_ORGN_CODE: '|| trans_b_rec.PASS_ORGN_CODE|| chr(10)||
                                              'v_date: '|| v_date||
                                              'v_NBRPTOT_BUDG_BASIS: '|| v_NBRPTOT_BUDG_BASIS||
                                              'v_NBRPTOT_ANN_BASIS: '|| v_NBRPTOT_ANN_BASIS||
                                              'v_NBRPTOT_BASE_UNITS: '|| v_NBRPTOT_BASE_UNITS||
                                              'v_nbrptot_appt_pct: '|| v_nbrptot_appt_pct||     chr(10)||
                                              'v_PTRECLS_CREATE_JFTE_IND: '|| v_PTRECLS_CREATE_JFTE_IND||
                                              'l_BUDGET_STATUS(indx): '|| l_BUDGET_STATUS(indx)||
                                              'v_NBRPTOT_BUDGET: '|| v_NBRPTOT_BUDGET||
                                              'l_BUDGET_ID(indx): '|| l_BUDGET_ID(indx)||  chr(10)||
                                              'l_BUDGET_PHASE(indx): '|| l_BUDGET_PHASE(indx)||
                                              'v_NTRPCLS_SGRP_CODE: '|| v_NTRPCLS_SGRP_CODE||
                                              'HPSS-1666 INSERT v_nbbposn_comment: '|| v_nbbposn_comment);
                                              
                                          SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                                          SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                                          dbms_output.put_line('1: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);    
                                          
                                          IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
                                                
												IF (l_BUDGET_STATUS(indx) = 'W' ) THEN --HPSS-1693
													v_create_year := (TO_NUMBER(v_FISC_YEAR)) - 1;
													--HPSS-1693 10/14/2019
													SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(v_create_year)) )  , to_date ('2-SEP-'||TO_CHAR(v_create_year))
													into v_NBRPTOT_EFFECTIVE_DATE , v_working_cutoff_date
													FROM dual;
													
													DBMS_OUTPUT.PUT_LINE ('v_create_year: '||v_create_year||' l_FISC_YEAR('||indx||')'||l_FISC_YEAR(indx)||' v_working_cutoff_date: '||v_working_cutoff_date);
													
														IF( trans_b_rec.PASS_EFFECTIVE_DATE < v_working_cutoff_date) then
															v_NBRPTOT_EFFECTIVE_DATE := to_date ('1-SEP-'||TO_CHAR(v_working_cutoff_date, 'YYYY')) ; 
														else
															v_NBRPTOT_EFFECTIVE_DATE := trans_b_rec.PASS_EFFECTIVE_DATE;
														end if;
													--HPSS-1693 10/14/2019
													DBMS_OUTPUT.PUT_LINE ('v_NBRPTOT_EFFECTIVE_DATE: '||v_NBRPTOT_EFFECTIVE_DATE);
                                                 
                                                END IF;  --HPSS-1693
                                             
                                             DBMS_OUTPUT.PUT_LINE (' v_NBRPTOT_EFFECTIVE_DATE: '||v_NBRPTOT_EFFECTIVE_DATE||' v_comment: '||v_comment);
                                               
                                            INSERT INTO NBRPTOT
                                            (
                                            NBRPTOT_POSN, NBRPTOT_FISC_CODE, NBRPTOT_EFFECTIVE_DATE, NBRPTOT_FTE,
                                  
                                            NBRPTOT_ORGN_CODE, NBRPTOT_ACTIVITY_DATE, NBRPTOT_BUDG_BASIS, NBRPTOT_ANN_BASIS,
                                  
                                            NBRPTOT_BASE_UNITS, NBRPTOT_APPT_PCT, NBRPTOT_CREATE_JFTE_IND,
                                  
                                             NBRPTOT_STATUS, NBRPTOT_COAS_CODE, NBRPTOT_BUDGET,
                                  
                                            NBRPTOT_ENCUMB, NBRPTOT_EXPEND, NBRPTOT_OBUD_CODE, NBRPTOT_OBPH_CODE,
                                  
                                            NBRPTOT_SGRP_CODE, NBRPTOT_BUDGET_FRNG, NBRPTOT_ENCUMB_FRNG, NBRPTOT_EXPEND_FRNG,
                                  
                                            NBRPTOT_ACCI_CODE_FRNG, NBRPTOT_FUND_CODE_FRNG, NBRPTOT_ORGN_CODE_FRNG, NBRPTOT_ACCT_CODE_FRNG,
                                  
                                            NBRPTOT_PROG_CODE_FRNG, NBRPTOT_ACTV_CODE_FRNG, NBRPTOT_LOCN_CODE_FRNG, NBRPTOT_RECURRING_BUDGET,
                                  
                                            NBRPTOT_COMMENT, NBRPTOT_USER_ID, NBRPTOT_DATA_ORIGIN, NBRPTOT_VPDI_CODE
                                            )
                                            VALUES
                                            (
                                            trans_b_rec.PASS_POSN_NBR, v_FISC_YEAR, v_NBRPTOT_EFFECTIVE_DATE, trans_b_rec.PASS_FTE,
                                  
                                            trans_b_rec.PASS_ORGN_CODE, v_date, v_NBRPTOT_BUDG_BASIS, v_NBRPTOT_ANN_BASIS,
                                  
                                            v_NBRPTOT_BASE_UNITS, v_nbrptot_appt_pct, v_PTRECLS_CREATE_JFTE_IND,
                                  
                                            l_BUDGET_STATUS(indx), trans_b_rec.PASS_COAS_CODE, v_NBRPTOT_BUDGET,
                                  
                                            null, null, l_BUDGET_ID(indx), l_BUDGET_PHASE(indx),
                                  
                                            v_NTRPCLS_SGRP_CODE, null, null, null,
                                  
                                            null, null, null, null,
                                  
                                            null, null, null, null,
                                  
                                            v_comment, 'TT_HR_PASS', null, null
                                            );   
                                                   
                                         end if;   --HPSS-1693        
                                                  
                                   end if;  --if(Nbrptot_rec1.ptot_fisc_code is null ) then
                             
                               EXIT WHEN CURSOR_NBRPTOT%notfound;
                               
                               
                               
                               
                          
                               v_comment := Nbrptot_rec1.ptot_comment;
                          
                               DBMS_OUTPUT.PUT_LINE (chr(10)|| 
                               'Nbrptot_rec.obud_code:  '||Nbrptot_rec1.obud_code||chr(10)||
                               'Nbrptot_rec.ptot_budg_basis:  '||' OLD: '||Nbrptot_rec1.ptot_budg_basis||' New: '||v_NBRPTOT_BUDG_BASIS||chr(10)||
                               'Nbrptot_rec.ptot_ann_basis :  '||' OLD: '||Nbrptot_rec1.ptot_ann_basis||' New: '||v_NBRPTOT_ANN_BASIS||chr(10)||
                               'Nbrptot_rec.ptot_base_units:  '||' OLD: '||Nbrptot_rec1.ptot_base_units||' New: '||v_NBRPTOT_BASE_UNITS||chr(10)||
                               'Nbrptot_rec.NBRPTOT_BUDGET:  '||Nbrptot_rec1.ptot_budget||' v_NBRPTOT_BUDGET: '||v_NBRPTOT_BUDGET||chr(10)||
                               'NBRPTOT_FISC_YEAR: '||Nbrptot_rec1.ptot_fisc_code||' v_FISC_YEAR: '||v_FISC_YEAR||chr(10)
                               );
                              
                                    
                                    
                                    --ptot_comment
                                    v_comment := NULL;
                                    
                                    /*select to_char(trans_b_rec.PASS_EFFECTIVE_DATE,'MM.DD.YYYY'),  to_char(v_date,'MM.DD.YYYY')
                                    into v_eff_date_char, v_date_char
                                    from dual;
                                    
                                    DBMS_OUTPUT.PUT_LINE ('v_eff_date_char, v_date_char'||v_eff_date_char||' , '||v_date_char); */
                                    
                                    SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                                    SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                                    dbms_output.put_line('2: v_extract_year: '||v_extract_year||' v_FISC_YEAR: '||v_FISC_YEAR||
                                    ' v_extract_date: '||v_extract_date||' trans_b_rec.PASS_EFFECTIVE_DATE : '||trans_b_rec.PASS_EFFECTIVE_DATE );    
                                          
                                    IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
                                    
                                    sql_stmt := 'UPDATE NBRPTOT SET ';
                                    v_NBRPTOT_FLG :=  NULL;
                                    --v_add_comment := v_date_char||' PASS '||pass_trans_no||' with Eff Date '||v_eff_date_char;
                                    v_add_comment := NULL;
                                    v_comment := fstringConcat(v_comment, v_add_comment);
                                    
                                    --compare nbrptot values with PASS
                                     IF Nbrptot_rec1.ptot_budg_basis != v_NBRPTOT_BUDG_BASIS THEN
                                     
                                     v_NBRPTOT_FLG := 'Y';
                                     
                                     sql_stmt := sql_stmt||' NBRPTOT_BUDG_BASIS = '''|| v_NBRPTOT_BUDG_BASIS ||'''';
                                     
                                     DBMS_OUTPUT.PUT_LINE ('Check 1: '||sql_stmt);
                                     
                                     v_add_comment := 'BUDG BASIS from '||Nbrptot_rec1.ptot_budg_basis||' to '||v_NBRPTOT_BUDG_BASIS;

                                     v_comment := fstringConcat(v_comment, v_add_comment);
                                                                                           
                                     END IF;
                                     
                                     IF Nbrptot_rec1.ptot_ann_basis != v_NBRPTOT_ANN_BASIS THEN
                                      --UPDATE NBRPTOT_ANN_BASIS
                                     if v_NBRPTOT_FLG = 'Y' then
                                     sql_stmt := sql_stmt||' , ';
                                     end if; 
                                     
                                     v_NBRPTOT_FLG := 'Y';
                                    
                                     sql_stmt := sql_stmt||' NBRPTOT_ANN_BASIS = '''|| v_NBRPTOT_ANN_BASIS ||'''';
                                     
                                     DBMS_OUTPUT.PUT_LINE ('Check 2: '||sql_stmt);
                                     
                                     v_add_comment := 'ANN BASIS from '||Nbrptot_rec1.ptot_ann_basis||' to '||v_NBRPTOT_ANN_BASIS;

                                     v_comment := fstringConcat(v_comment, v_add_comment);
                                     
                                     end if;
                                     
                                     IF Nbrptot_rec1.ptot_base_units != v_NBRPTOT_BASE_UNITS THEN
                                      --UPDATE NBRPTOT_BASE_BASIS
                                         if v_NBRPTOT_FLG = 'Y' then
                                         sql_stmt := sql_stmt||' , ';
                                         end if;
                                     
                                         v_NBRPTOT_FLG := 'Y';

                                         sql_stmt := sql_stmt||' NBRPTOT_BASE_UNITS = '''|| v_NBRPTOT_BASE_UNITS ||'''';
                                         
                                         DBMS_OUTPUT.PUT_LINE ('Check 3: '||sql_stmt);
                                         
                                         v_add_comment := 'BASE UNITS from '||Nbrptot_rec1.ptot_base_units||' to '||v_NBRPTOT_BASE_UNITS;

                                         v_comment := fstringConcat(v_comment, v_add_comment);

                                      END IF;
                                      
                                      --PASS_FTE
                                      IF trans_b_rec.PASS_FTE != Nbrptot_rec1.ptot_fte THEN
                                      --UPDATE NBRPTOT_FTE
                                         if v_NBRPTOT_FLG = 'Y' then
                                         sql_stmt := sql_stmt||' , ';
                                         end if;
                                     
                                         v_NBRPTOT_FLG := 'Y';

                                       
                                         sql_stmt := sql_stmt||' NBRPTOT_FTE = '''|| trans_b_rec.PASS_FTE ||'''';
                                         
                                         DBMS_OUTPUT.PUT_LINE ('Check 4: '||sql_stmt);
                                         
                                         v_add_comment := 'FTE from '||Nbrptot_rec1.ptot_fte||' to '||trans_b_rec.PASS_FTE;

                                         v_comment := fstringConcat(v_comment, v_add_comment);

                                      END IF;
                                      
                                     v_PTOT_APP_BDG :=   v_NBRPTOT_BUDGET - (nvl(v_PTOT_TRANS_BDG,0));
                                     DBMS_OUTPUT.PUT_LINE (
                                     'v_PTOT_APP_BDG'||chr(9)||v_PTOT_APP_BDG||
                                     'v_NBRPTOT_BUDGET'||chr(9)||v_NBRPTOT_BUDGET||
                                     'v_PTOT_TRANS_BDG'||chr(9)||v_PTOT_TRANS_BDG||
                                     'trans_b_rec.PASS_FTE'||chr(9)||trans_b_rec.PASS_FTE||
                                     'trans_b_rec.PASS_RATE_OF_PAY'||chr(9)||trans_b_rec.PASS_RATE_OF_PAY
                                     );
                                      
                                     IF Nbrptot_rec1.ptot_budget != v_PTOT_APP_BDG THEN
                                     
                                      --UPDATE  NBRPTOT_BUDGET
                                     if v_NBRPTOT_FLG = 'Y' then
                                     sql_stmt := sql_stmt||' , ';
                                     end if;
                                     
                                      
                                     v_NBRPTOT_FLG := 'Y'; 
                                     
                                     sql_stmt := sql_stmt||' NBRPTOT_BUDGET = '''|| v_PTOT_APP_BDG ||'''';
                                     --v_comment :=   'BUDGET from '||Nbrptot_rec1.ptot_budget||' to '||v_PTOT_APP_BDG;
                        
                                     END IF;  
                                     
                                     IF v_NBRPTOT_FLG = 'Y' then
                                     
										DBMS_OUTPUT.PUT_LINE ('trans_b_rec.PASS_COAS_CODE: '||trans_b_rec.PASS_COAS_CODE);
                                         if trans_b_rec.PASS_COAS_CODE = 'E' then
											v_comment := NULL;
											--HPSS-1666
											DBMS_OUTPUT.PUT_LINE ('trans_b_rec.PASS_TRANS_ID: '||trans_b_rec.PASS_TRANS_ID);
											OPEN Chart_E_Budget_Comments(trans_b_rec.PASS_TRANS_ID);
											LOOP 
												FETCH Chart_E_Budget_Comments BULK COLLECT INTO l_COMMENT_DESC
												LIMIT 1000;
													FOR budg_indx IN 1 .. l_COMMENT_DESC.COUNT
													LOOP
													DBMS_OUTPUT.PUT_LINE ('l_COMMENT_DESC('||budg_indx||'): '||l_COMMENT_DESC(budg_indx));
													if (v_comment is null) then
														v_comment := l_COMMENT_DESC(budg_indx);
													else
														v_comment := v_comment||chr(10)||l_COMMENT_DESC(budg_indx);
													end if;
													END LOOP;		
											EXIT WHEN Chart_E_Budget_Comments%NOTFOUND;
											END LOOP;
											CLOSE Chart_E_Budget_Comments;
											--HPSS-1666
                                             /*SELECT LISTAGG(COMMENT_DESC, ' ') WITHIN GROUP (ORDER BY ACTIVITY_DATE desc) into v_comment
                                             from tt_hr_pass.nc_pass_comments_R where AREA = 'budget' and NC_PASS_TRANS_B_ID = trans_b_rec.PASS_TRANS_ID and user_id <> 'NPR System';*/
                                         
                                         --else
                                         end if;
										v_comment := fstringConcat(v_comment,Nbrptot_rec1.ptot_comment );     
                                        
										DBMS_OUTPUT.PUT_LINE ('RC Chart: '||trans_b_rec.PASS_COAS_CODE ||' '||v_comment);
 
                                     utl_file.put_line(wfile_handle,v_comment);
                                     
                                     v_comment := REPLACE(v_comment,'''', ''''' ');
                                     
                                     DBMS_OUTPUT.PUT_LINE ('HPSS-1666: UPDATE NBRPTOT_COMMENT: '||v_comment );
                                     
                                     sql_stmt := sql_stmt||' ,  NBRPTOT_COMMENT = '''|| v_comment ||''''||
                                     ' ,  NBRPTOT_USER_ID = ''TT_HR_PASS'''||
                                     ' ,  NBRPTOT_ACTIVITY_DATE = '''|| v_date ||''''||
                                     '  where NBRPTOT_POSN = '''|| trans_b_rec.PASS_POSN_NBR ||''''||
                                     '  AND NBRPTOT_FISC_CODE = '''|| v_FISC_YEAR ||''''||
                                     '  AND NBRPTOT_STATUS IN ( ''A'', ''W'')' ;
                                     --There will be only one A Approved record for one fiscal year and that alone needs to be updated
                                                                               
                                     DBMS_OUTPUT.PUT_LINE (v_comment||chr(10)||'QUERY: '||chr(10)||sql_stmt);
                                     
                                           EXECUTE IMMEDIATE sql_stmt;
                                     
                                     end if; 
                                     
                                   end if;  --HPSS-1693                                     
                          
                              END LOOP;      
                              CLOSE CURSOR_NBRPTOT;
                              DBMS_OUTPUT.PUT_LINE (chr(10)||'NBRPLBD PARAMETERS'||chr(10)||
                              'trans_b_rec.PASS_POSN_NBR: '||trans_b_rec.PASS_POSN_NBR||chr(10)||
                              'v_FISC_YEAR: '||v_FISC_YEAR||chr(10)||
                              'l_BUDGET_ID(indx)'||l_BUDGET_ID(indx)||chr(10)||
                              'l_BUDGET_PHASE(indx)'||l_BUDGET_PHASE(indx)||chr(10)
                              );
                              
                                                     
                              
                          END LOOP;
                EXIT WHEN CURSOR_FISCYEAR%NOTFOUND;  
                          
                END LOOP;
           
           CLOSE CURSOR_FISCYEAR;   
           
           
           
           OPEN CURSOR_NBRPLBD_FISCYEAR(trans_b_rec.PASS_COAS_CODE, pass_trans_no );
           
           LOOP        -- CURSOR_NBRPLBD_FISCYEAR(trans_b_rec.PASS_COAS_CODE, pass_trans_no );
            FETCH CURSOR_NBRPLBD_FISCYEAR
            BULK COLLECT INTO l_FISC_YEAR,
                              l_BUDGET_ID,
                              l_BUDGET_PHASE,
                              l_BUDGET_STATUS,
                              l_PASS_POSN_NBR,
                              l_PASS_COAS_CODE, 
                              l_PASS_FUND_CODE, 
                              l_PASS_ORGN_CODE,
                              
                              l_PASS_ACCT_CODE, 
            
                              l_PASS_POSN_PROG_CODE,                 
                              l_PASS_POSN_CURR_ACCT_PERC,              
                              l_PASS_POSN_PROP_ACCT_PERC,
                              l_PASS_POSN_PROP_FOP_AMT   
            LIMIT 1000;
            DBMS_OUTPUT.PUT_LINE('l_FISC_YEAR.COUNT'||chr(9)||l_FISC_YEAR.COUNT);
            DBMS_OUTPUT.PUT_LINE (chr(10)||
              'T v_PLBD_Count'||chr(9)||
              'T l_FISC_YEAR'||chr(9)|| l_FISC_YEAR(1)||--  chr(9)|| l_FISC_YEAR(2)||  chr(9)||
              'T v_NBRPTOT_BUDGET'||chr(9)||
              'T v_NBRPLBD_BUDGET'||chr(9)||
              
              'T l_BUDGET_ID'||chr(9)||
              'T l_BUDGET_PHASE'||chr(9)||
              'T l_BUDGET_STATUS'||chr(9)||
                                     
              'T l_PASS_ORGN_CODE'||chr(9)||
              'T l_PASS_POSN_NBR'||chr(9)||l_PASS_POSN_NBR(1) || chr(9)||
              'T l_PASS_COAS_CODE'||chr(9)|| 
              
              'T l_PASS_FUND_CODE'||chr(9)|| 
              'T l_PASS_ACCT_CODE'||chr(9)|| l_PASS_ACCT_CODE(1)||chr(9)||
              'T l_PASS_POSN_PROG_CODE'||chr(9)||                 
              
              'T l_PASS_POSN_CURR_ACCT_PERC'||chr(9)||              
              'T l_PASS_POSN_PROP_ACCT_PERC'
              
              );
            FOR indx IN 1 .. l_FISC_YEAR.COUNT
                                 
             LOOP     --FOR indx IN 1 .. l_FISC_YEAR.COUNT
                  
                  v_FISC_YEAR := 20 ||l_FISC_YEAR(indx);
                                                      
                  --select count(*) into v_PLBD_Count
                  --from NBRPLBD
                  --WHERE NBRPLBD_POSN    =  l_PASS_POSN_NBR(indx)
                  --and NBRPLBD_FISC_CODE =  v_FISC_YEAR
                  --AND NBRPLBD_COAS_CODE =  l_PASS_COAS_CODE(indx)
                  --AND NBRPLBD_FUND_CODE =  l_PASS_FUND_CODE(indx)
                  --AND NBRPLBD_ORGN_CODE =  l_PASS_ORGN_CODE(indx)
                  --AND NBRPLBD_ACCT_CODE =  l_PASS_ACCT_CODE(indx) ACCT_CODE  changes in the PASS Application
                  --AND NBRPLBD_PROG_CODE =  l_PASS_POSN_PROG_CODE(indx)
                  --AND NBRPLBD_PERCENT   =  l_PASS_POSN_CURR_ACCT_PERC(indx);
                  
                  SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                  SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                  dbms_output.put_line('3: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);    
                                          
                  IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
                        
                        --update account code on ALL nNBRPLBD RECORDS FOR THAT POSITION AND ACTIVE FISCAL YEAR
                        sql_stmt :=  ' update NBRPLBD 
                        set NBRPLBD_ACCT_CODE  = '''||l_PASS_ACCT_CODE(indx)||''''||
                        ' , '||'NBRPLBD_USER_ID = ''TT_HR_PASS'''||
                        ' , '||' NBRPLBD_ACTIVITY_DATE = '''||v_date||''''||
                        'where NBRPLBD_POSN = '''||l_PASS_POSN_NBR(indx)||''''||
                        'and NBRPLBD_FISC_CODE = '''||v_FISC_YEAR||''''||
                        ' AND NBRPLBD_PERCENT > 0'; 
                        
                        EXECUTE IMMEDIATE sql_stmt;
                        
                  end if;  --HPSS-1693
                  
                  sql_stmt :=  ' select count(*) 
                  from NBRPLBD
                  WHERE NBRPLBD_POSN    =  '''||l_PASS_POSN_NBR(indx)||'''
                  and NBRPLBD_FISC_CODE =  '''||v_FISC_YEAR||'''
                  AND NBRPLBD_COAS_CODE =  '''||l_PASS_COAS_CODE(indx)||'''
                  AND NBRPLBD_FUND_CODE =  '''||l_PASS_FUND_CODE(indx)||'''
                  AND NBRPLBD_ORGN_CODE =  '''||l_PASS_ORGN_CODE(indx)||'''
                  AND NBRPLBD_ACCT_CODE  = '''||l_PASS_ACCT_CODE(indx)||'''
                  AND NBRPLBD_PROG_CODE =  '''||l_PASS_POSN_PROG_CODE(indx)||'''
                  AND NBRPLBD_PERCENT   > 0 AND NBRPLBD_CHANGE_IND IS NULL';
                  --AND NBRPLBD_PERCENT   =  '''||l_PASS_POSN_CURR_ACCT_PERC(indx)||'''';
                  
                  EXECUTE IMMEDIATE sql_stmt INTO v_PLBD_Count;
                  
                  dbms_output.put_line('v_PLBD_Count SQL:'||chr(10)||sql_stmt);
                  
                  
                  select count(*) INTO v_PTOT_BDG_CNT
                  from NBRPTOT WHERE 
                  NBRPTOT_POSN          = l_PASS_POSN_NBR(indx)
                  AND NBRPTOT_FISC_CODE =  v_FISC_YEAR
                  AND NBRPTOT_OBUD_CODE = l_BUDGET_ID(indx)
                  AND NBRPTOT_OBPH_CODE = l_BUDGET_PHASE(indx)
                  AND NBRPTOT_STATUS IN ('A','T','W');
                  
                  if (v_PTOT_BDG_CNT > 0 )then
                    
                    select sum(NBRPTOT_BUDGET) INTO v_NBRPTOT_BUDGET
                    from NBRPTOT WHERE 
                    NBRPTOT_POSN          = l_PASS_POSN_NBR(indx)
                    AND NBRPTOT_FISC_CODE =  v_FISC_YEAR
                    AND NBRPTOT_OBUD_CODE = l_BUDGET_ID(indx)
                    AND NBRPTOT_OBPH_CODE = l_BUDGET_PHASE(indx)
                    AND NBRPTOT_STATUS IN ('A','T','W');
                    
                    
                     v_NBRPLBD_BUDGET := round((round(v_NBRPTOT_BUDGET,2) * round(l_PASS_POSN_PROP_ACCT_PERC(indx)/100, 4)),2);
                    
                  end if;
                  
                  DBMS_OUTPUT.PUT_LINE (chr(10)||
                     v_PLBD_Count||chr(9)||
                     l_FISC_YEAR(indx)||chr(9)||
                     v_NBRPTOT_BUDGET||chr(9)||
                     v_NBRPLBD_BUDGET||chr(9)||
                      
                     l_BUDGET_ID(indx)||chr(9)||
                     l_BUDGET_PHASE(indx)||chr(9)||
                     l_BUDGET_STATUS(indx)||chr(9)||
                                             
                     l_PASS_ORGN_CODE(indx)||chr(9)||
                     l_PASS_POSN_NBR(indx)||chr(9)||
                     l_PASS_COAS_CODE(indx)||chr(9)|| 
                      
                     l_PASS_FUND_CODE(indx)||chr(9)|| 
                     l_PASS_ACCT_CODE(indx)||chr(9)||
                     l_PASS_POSN_PROG_CODE(indx)||chr(9)||                 
                      
                     l_PASS_POSN_CURR_ACCT_PERC(indx)||chr(9)||              
                     l_PASS_POSN_PROP_ACCT_PERC(indx)
                      
                      );
                      
                  dbms_output.put_line('v_FISC_YEAR: '||v_FISC_YEAR||'v_PLBD_Count: '||v_PLBD_Count||'v_PTOT_BDG_CNT: '||v_PTOT_BDG_CNT);  
                    
                  IF ( (v_PLBD_Count = 0) AND (v_PTOT_BDG_CNT > 0) ) then   --  END IF;   --IF ((v_PLBD_Count = 0) AND ((v_PTOT_BDG_CNT > 0 ) ) then          
                  
                    SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                    SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                    dbms_output.put_line('4: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);    
                                          
                    IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
                           
                            insert into NBRPLBD(
                
                              NBRPLBD_POSN,  NBRPLBD_FISC_CODE, NBRPLBD_PERCENT,NBRPLBD_ACTIVITY_DATE,
                
                              NBRPLBD_COAS_CODE, NBRPLBD_ACCI_CODE,
                
                              NBRPLBD_FUND_CODE, NBRPLBD_ORGN_CODE, NBRPLBD_ACCT_CODE, NBRPLBD_PROG_CODE,
                
                              NBRPLBD_ACTV_CODE, NBRPLBD_LOCN_CODE, NBRPLBD_ACCT_CODE_EXTERNAL, NBRPLBD_OBUD_CODE,
                
                              NBRPLBD_OBPH_CODE,  NBRPLBD_CHANGE_IND, NBRPLBD_PROJ_CODE, NBRPLBD_CTYP_CODE,
                
                              NBRPLBD_BUDGET, NBRPLBD_BUDGET_TO_POST, NBRPLBD_USER_ID, NBRPLBD_DATA_ORIGIN,
                
                              NBRPLBD_VPDI_CODE)
                              VALUES
                              (
                
                              l_PASS_POSN_NBR(indx), v_FISC_YEAR, l_PASS_POSN_PROP_ACCT_PERC(indx), v_date,
                
                              l_PASS_COAS_CODE(indx), null,
                
                              l_PASS_FUND_CODE(indx), l_PASS_ORGN_CODE(indx), l_PASS_ACCT_CODE(indx), l_PASS_POSN_PROG_CODE(indx),
                
                              null, null, null, l_BUDGET_ID(indx),
                
                              l_BUDGET_PHASE(indx),  null, null, null,
                
                              v_NBRPLBD_BUDGET, 0, 'TT_HR_PASS', NULL,
                
                              NULL
                
                              );

                        dbms_output.put_line(
                        'NBRPLBD_POSN: '||chr(9)||l_PASS_ORGN_CODE(indx)||chr(9)              ||'NBRPLBD_FISC_CODE'||chr(9)||v_FISC_YEAR||chr(9)||
                        'NBRPLBD_PERCENT'||chr(9)||l_PASS_POSN_PROP_ACCT_PERC(indx)||chr(9)   ||'NBRPLBD_ACTIVITY_DATE'||chr(9)||v_date||chr(9)||
                        'NBRPLBD_COAS_CODE'||chr(9)||l_PASS_COAS_CODE(indx)||chr(9)           ||'NBRPLBD_FUND_CODE'||chr(9)||l_PASS_FUND_CODE(indx)||chr(9)||
                        'NBRPLBD_ORGN_CODE'||chr(9)||l_PASS_ORGN_CODE(indx)||chr(9)           ||'NBRPLBD_ACCT_CODE'||chr(9)||l_PASS_ORGN_CODE(indx)||chr(9)||
                        'NBRPLBD_PROG_CODE'||chr(9)||l_PASS_ORGN_CODE(indx)||chr(9)           ||'NBRPLBD_OBUD_CODE'||chr(9)||l_BUDGET_ID(indx)||chr(9)||
                        'NBRPLBD_OBPH_CODE'||chr(9)||l_BUDGET_PHASE(indx)||chr(9)             ||'NBRPLBD_USER_ID'||chr(9)||l_PASS_ORGN_CODE(indx)             
                        );
                        
                    end if; --HPSS-1693
                        
                  ELSIF ( (v_PLBD_Count > 0) AND (v_PTOT_BDG_CNT > 0) )  THEN     --IF ((v_PLBD_Count = 0) AND ((v_PTOT_BDG_CNT > 0 ) ) then
                  
                  v_NBRPLBD_FLG  := NULL;
                  
                  sql_stmt :=  'select NBRPLBD_FUND_CODE, NBRPLBD_ORGN_CODE, NBRPLBD_ACCT_CODE, 
                  NBRPLBD_PROG_CODE, NBRPLBD_PERCENT, NBRPLBD_BUDGET 
                  from  NBRPLBD
                  WHERE NBRPLBD_POSN    =  '''||l_PASS_POSN_NBR(indx)||'''
                  and NBRPLBD_FISC_CODE =  '''||v_FISC_YEAR||'''
                  AND NBRPLBD_COAS_CODE =  '''||l_PASS_COAS_CODE(indx)||'''
                  AND NBRPLBD_FUND_CODE =  '''||l_PASS_FUND_CODE(indx)||'''
                  AND NBRPLBD_ORGN_CODE =  '''||l_PASS_ORGN_CODE(indx)||'''
                  AND NBRPLBD_ACCT_CODE  = '''||l_PASS_ACCT_CODE(indx)||'''
                  AND NBRPLBD_PROG_CODE =  '''||l_PASS_POSN_PROG_CODE(indx)||'''
                  AND NBRPLBD_PERCENT   > 0 AND NBRPLBD_CHANGE_IND IS NULL';
                  
                  dbms_output.put_line('ELSIF ( (v_PLBD_Count > 0) AND (v_PTOT_BDG_CNT > 0) ): '||chr(10)||sql_stmt);
                        
                  EXECUTE IMMEDIATE sql_stmt INTO Nbrplbd_rec1;
                  SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                  SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                  dbms_output.put_line('5: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);    
                                          
                  IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693
                          
                          sql_stmt := 'Update NBRPLBD SET ';
                
                            IF Nbrplbd_rec1.bnr_plbd_percent != l_PASS_POSN_PROP_ACCT_PERC(indx)  THEN
              
                                v_NBRPLBD_FLG  := 'Y';
                                sql_stmt :=  sql_stmt||' NBRPLBD_PERCENT = '''|| l_PASS_POSN_PROP_ACCT_PERC(indx) ||'''';
                                v_add_comment :=  'NBRPLBD_PERCENT was updated by PASS  from '||Nbrplbd_rec1.bnr_plbd_percent||' to '||l_PASS_POSN_PROP_ACCT_PERC(indx);
                                v_comment := fstringConcat(v_comment, v_add_comment);
                
                            END IF;
                            
                            IF Nbrplbd_rec1.bnr_plbd_acct_code != l_PASS_ACCT_CODE(indx)  THEN
                
                                if v_NBRPLBD_FLG  = 'Y' then
                                sql_stmt :=  sql_stmt||' , ';
                                end if;
                
                                v_NBRPLBD_FLG  := 'Y';
                                sql_stmt :=  sql_stmt||' NBRPLBD_ACCT_CODE = '''||l_PASS_ACCT_CODE(indx)||'''';
                                v_add_comment := 'NBRPLBD_BUDGET was updated by PASS from '||Nbrplbd_rec1.bnr_plbd_acct_code||' to '||l_PASS_ACCT_CODE(indx);
                                v_comment := fstringConcat(v_comment, v_add_comment);
                
                            END IF;
                
                            IF v_NBRPLBD_BUDGET != (nvl(Nbrplbd_rec1.bnr_plbd_budget,0))  THEN
                
                                if v_NBRPLBD_FLG  = 'Y' then
                                sql_stmt :=  sql_stmt||' , ';
                                end if;
                
                                v_NBRPLBD_FLG  := 'Y';
                                sql_stmt :=  sql_stmt||' NBRPLBD_BUDGET = '''||v_NBRPLBD_BUDGET||'''';
                                v_add_comment := 'NBRPLBD_BUDGET was updated by PASS from '||Nbrplbd_rec1.bnr_plbd_budget||' to '||v_NBRPLBD_BUDGET;
                                v_comment := fstringConcat(v_comment, v_add_comment);
                
                            END IF;
                
                
                            IF v_NBRPLBD_FLG = 'Y' THEN
                
                              utl_file.put_line(wfile_handle,v_comment);
                
                              sql_stmt :=   sql_stmt||' , '||' NBRPLBD_USER_ID = ''TT_HR_PASS''' ||
                                           ' , '||' NBRPLBD_ACTIVITY_DATE = '''||v_date||'''' ||
                                           ' , '||' NBRPLBD_BUDGET_TO_POST = ''0''' ||
                                           ' where NBRPLBD_POSN = '''|| trans_b_rec.PASS_POSN_NBR ||''''||
                                           ' AND NBRPLBD_FISC_CODE = '''|| v_FISC_YEAR ||''''||
                                           ' AND NBRPLBD_OBUD_CODE = '''|| l_BUDGET_ID(indx) ||''''||
                                           ' AND NBRPLBD_OBPH_CODE = '''|| l_BUDGET_PHASE(indx) ||''''||
                                           ' AND NBRPLBD_FUND_CODE =  '''||l_PASS_FUND_CODE(indx)||''''||
                                           ' AND NBRPLBD_ORGN_CODE =  '''||l_PASS_ORGN_CODE(indx)||''''||
                                           ' AND NBRPLBD_ACCT_CODE =  '''||l_PASS_ACCT_CODE(indx)||''''||
                                           ' AND NBRPLBD_PROG_CODE =  '''||l_PASS_POSN_PROG_CODE(indx)||''''||
                                           ' AND NBRPLBD_CHANGE_IND IS NULL';
                
                
                              DBMS_OUTPUT.PUT_LINE (v_comment||chr(10)||'NBRPLBD QUERY: '||chr(10)||sql_stmt);
                
                              EXECUTE IMMEDIATE sql_stmt;
                          
                            END IF;  
                      end if; --HPSS-1693      
                  
                  END IF;   --IF ((v_PLBD_Count = 0) AND ((v_PTOT_BDG_CNT > 0 ) ) then     
          
          END LOOP; --FOR indx IN 1 .. l_FISC_YEAR.COUNT
                
          EXIT WHEN CURSOR_NBRPLBD_FISCYEAR%NOTFOUND;

      END LOOP;  -- CURSOR_NBRPLBD_FISCYEAR(trans_b_rec.PASS_COAS_CODE, pass_trans_no );
      
      OPEN CURSOR_DEL_PLBD(trans_b_rec.PASS_COAS_CODE);

        LOOP
        FETCH CURSOR_DEL_PLBD
        BULK COLLECT INTO l_FISC_YEAR
        LIMIT 1000;
        DBMS_OUTPUT.PUT_LINE(' CURSOR_DEL_PLBD l_FISC_YEAR.COUNT'||chr(9)||l_FISC_YEAR.COUNT);
          FOR indx IN 1 .. l_FISC_YEAR.COUNT
                LOOP
                v_FISC_YEAR    := 20||l_FISC_YEAR(indx);
                v_add_comment  := '';
                  
                      
                      
                      
                      --Update comments for FOPs that were converted to 0 by PASS
                     select count(*) into v_DEL_PLBD_CMT 
                     from  tt_hr_pass.nc_pass_transfunding_r
                     where nc_pass_trans_b_id = trans_b_rec.PASS_TRANS_ID and  POSN_PROPOSED_ACCT_PERCENT = 0;
                      
                      IF(v_DEL_PLBD_CMT > 0 ) then
                        FOR loop_elem IN (select posn_coas_code, posn_fund_code, posn_orgn_code, posn_acct_code, posn_prog_code, POSN_CURRENT_ACCT_PERCENT, POSN_PROPOSED_ACCT_PERCENT
                                          from  tt_hr_pass.nc_pass_transfunding_r
                                          where nc_pass_trans_b_id = trans_b_rec.PASS_TRANS_ID and  POSN_PROPOSED_ACCT_PERCENT = 0)
                          LOOP
                          
                          IF (v_add_comment IS NULL) THEN
                                v_add_comment :=     'FOP '||loop_elem.posn_fund_code||' '||loop_elem.posn_orgn_code||' '||loop_elem.posn_prog_code||
                                                     ' from '||loop_elem.POSN_CURRENT_ACCT_PERCENT||' to 0 %';                                                                                                                                                                        
                          ELSE
                                v_add_comment :=     v_add_comment||chr(10)||'FOP '||loop_elem.posn_fund_code||' '||loop_elem.posn_orgn_code||' '||loop_elem.posn_prog_code||
                                             ' from '||loop_elem.POSN_CURRENT_ACCT_PERCENT||' to 0 %';
                                             
                          END IF;                    
                          
                          DBMS_OUTPUT.PUT_LINE(' v_DEL_PLBD_CMT v_add_comment: '||chr(9)||v_add_comment);
                                         
                          END LOOP;
                                          
                      END IF;
                      
                      v_DEL_PLBD_CMT := 0;
                      
                      --Update preexisting records to zero in comment
                      
                      select count(*) into v_DEL_PLBD_CMT from nbrplbd
                      where 
                      (nbrplbd_coas_code, nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_acct_code, nbrplbd_prog_code, nbrplbd_percent ) NOT IN
                      (select posn_coas_code, posn_fund_code, posn_orgn_code, posn_acct_code, posn_prog_code, POSN_PROPOSED_ACCT_PERCENT from
                      tt_hr_pass.nc_pass_transfunding_r
                      where 
                      nc_pass_trans_b_id = trans_b_rec.PASS_TRANS_ID)
                      and nbrplbd_posn = trans_b_rec.PASS_POSN_NBR and nbrplbd_fisc_code = v_FISC_YEAR and nbrplbd_percent > 0;
                      
                      DBMS_OUTPUT.PUT_LINE(' v_DEL_PLBD_CMT: '||chr(9)||v_DEL_PLBD_CMT);
                      
                      IF(v_DEL_PLBD_CMT > 0 ) then
                        FOR loop_elem IN (select nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_prog_code, nbrplbd_percent from nbrplbd where 
                                          (nbrplbd_coas_code, nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_acct_code, nbrplbd_prog_code, nbrplbd_percent) NOT IN
                                          (select posn_coas_code, posn_fund_code, posn_orgn_code, posn_acct_code, posn_prog_code, POSN_PROPOSED_ACCT_PERCENT from
                                          tt_hr_pass.nc_pass_transfunding_r
                                          where 
                                          nc_pass_trans_b_id = trans_b_rec.PASS_TRANS_ID)
                                          and nbrplbd_posn = trans_b_rec.PASS_POSN_NBR and nbrplbd_fisc_code = v_FISC_YEAR and nbrplbd_percent > 0)
                          LOOP
                          
                          IF (v_add_comment IS NULL) THEN
                                v_add_comment :=     'FOP '||loop_elem.nbrplbd_fund_code||' '||loop_elem.nbrplbd_orgn_code||' '||loop_elem.nbrplbd_prog_code||
                                                     ' from '||loop_elem.nbrplbd_percent||' to 0 %';                                                                                                                                                                        
                          ELSE
                                v_add_comment :=     v_add_comment||chr(10)||'FOP '||loop_elem.nbrplbd_fund_code||' '||loop_elem.nbrplbd_orgn_code||' '
                                                     ||loop_elem.nbrplbd_prog_code||' from '||loop_elem.nbrplbd_percent||' to 0 %';
                          END IF;
                          DBMS_OUTPUT.PUT_LINE(' v_DEL_PLBD_CMT v_add_comment: '||chr(9)||v_add_comment);
                                         
                          END LOOP;
                                          
                      END IF;
                      
                      
                      --Update Comment with FOPS equal to 0
                      select count(*) into v_NEW_PLBD_CMT from nbrplbd 
                      where nbrplbd_posn = trans_b_rec.PASS_POSN_NBR
                      and nbrplbd_fisc_code in v_FISC_YEAR
                      and nbrplbd_percent > 0 ; 
                      
                      if (v_NEW_PLBD_CMT > 0)then
                          FOR loop_elem IN (select  nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_prog_code, nbrplbd_percent , POSN_CURRENT_ACCT_PERCENT
                                            from nbrplbd, tt_hr_pass.nc_pass_trans_b t,  tt_hr_pass.nc_pass_transfunding_r f 
                                            where nbrplbd_posn = trans_b_rec.PASS_POSN_NBR    and nbrplbd_fisc_code in v_FISC_YEAR   and nbrplbd_percent > 0 and
                                            t. trans_no  =  pass_trans_no and f.NC_PASS_TRANS_B_ID = t.trans_id and f.POSN_FUND_CODE     = nbrplbd_fund_code 
                                            and f.POSN_ORGN_CODE     = nbrplbd_orgn_code and f.POSN_PROG_CODE     = nbrplbd_prog_code )
                          LOOP
                          
                          /*select POSN_CURRENT_ACCT_PERCENT into v_curr_pec from tt_hr_pass.nc_pass_trans_b t,  tt_hr_pass.nc_pass_transfunding_r f
                          where t. trans_no  = pass_trans_no
                          and f.NC_PASS_TRANS_B_ID = t.trans_id
                          and f.POSN_FUND_CODE     = loop_elem.nbrplbd_fund_code 
                          and f.POSN_ORGN_CODE     = loop_elem.nbrplbd_orgn_code
                          and f.POSN_PROG_CODE     = loop_elem.nbrplbd_prog_code  ;  */
                          
                          IF (v_add_comment IS NULL) THEN
                                v_add_comment :=     'FOP '||loop_elem.nbrplbd_fund_code||' '||loop_elem.nbrplbd_orgn_code||' '||loop_elem.nbrplbd_prog_code;
                                IF (loop_elem.POSN_CURRENT_ACCT_PERCENT > 0) then
                                      v_add_comment := v_add_comment ||' from '|| loop_elem.POSN_CURRENT_ACCT_PERCENT ||'% ';
                                end if;   
                                v_add_comment :=    v_add_comment||' updated to '||loop_elem.nbrplbd_percent||'%';                                                                                                                                                                        
                          ELSE
                                v_add_comment :=     v_add_comment||chr(10)||'FOP '||loop_elem.nbrplbd_fund_code||' '||loop_elem.nbrplbd_orgn_code||' '||loop_elem.nbrplbd_prog_code;
                                IF (loop_elem.POSN_CURRENT_ACCT_PERCENT > 0) then
                                      v_add_comment := v_add_comment ||' from '|| loop_elem.POSN_CURRENT_ACCT_PERCENT ||'% ';
                                end if; 
                                v_add_comment := v_add_comment ||' updated to '||loop_elem.nbrplbd_percent||'%';
                          END IF;
                          DBMS_OUTPUT.PUT_LINE(' v_NEW_PLBD_CMT v_add_comment: '||chr(9)||v_add_comment);
                                         
                          END LOOP;
                      end if;
                      
                      --HPSS-1708
                   
                      select   count(*) into v_NEW_PLBD_CMT 
                      from nbrplbd  where  nbrplbd_posn = trans_b_rec.PASS_POSN_NBR    and nbrplbd_fisc_code in v_FISC_YEAR and nbrplbd_percent > 0 
                      and (nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_prog_code) NOT IN 
                      ( select POSN_FUND_CODE, POSN_ORGN_CODE, POSN_PROG_CODE from tt_hr_pass.nc_pass_transfunding_r where NC_PASS_TRANS_B_ID = trans_b_rec.PASS_TRANS_ID
                      );
                      
                      if (v_NEW_PLBD_CMT > 0)then
                      DBMS_OUTPUT.PUT_LINE(' v_NEW_PLBD_CMT: '||chr(9)||v_NEW_PLBD_CMT);
                          FOR loop_jlbd IN (select   nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_prog_code, nbrplbd_percent 
                                            from nbrplbd  where  nbrplbd_posn = trans_b_rec.PASS_POSN_NBR    and nbrplbd_fisc_code in v_FISC_YEAR and nbrplbd_percent > 0 
                                            and (nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_prog_code) NOT IN 
                                            (select POSN_FUND_CODE, POSN_ORGN_CODE, POSN_PROG_CODE from tt_hr_pass.nc_pass_transfunding_r where NC_PASS_TRANS_B_ID = trans_b_rec.PASS_TRANS_ID) )
                          LOOP
                          
                          IF (v_add_comment IS NULL) THEN
                                v_add_comment :=     'FOP '||loop_jlbd.nbrplbd_fund_code||' '||loop_jlbd.nbrplbd_orgn_code||' '||loop_jlbd.nbrplbd_prog_code||
                                                     ' updated from '||loop_jlbd.nbrplbd_percent||'% to 0%';
                          ELSE
                                v_add_comment :=     v_add_comment||chr(10)||'FOP '||loop_jlbd.nbrplbd_fund_code||' '||loop_jlbd.nbrplbd_orgn_code||' '||loop_jlbd.nbrplbd_prog_code||
                                                     ' updated from '||loop_jlbd.nbrplbd_percent||'% to 0%';
                          END IF;
                          DBMS_OUTPUT.PUT_LINE(' v_NEW_PLBD_CMT v_add_comment: '||chr(9)||v_add_comment);
                                         
                          END LOOP;  
                      end if;    --HPSS-1708
                      
                      select sum(POSN_PROPOSED_ANNUAL_FOAP_AMT), sum(POSN_CURRENT_ANNUAL_FOAP_AMT) into v_PASS_BUDGET, v_TOT_BUDGET from tt_hr_pass.nc_pass_transfunding_R 
                      where NC_PASS_TRANS_B_ID = trans_b_rec.PASS_TRANS_ID ;
                      v_add_comment :=     v_add_comment||chr(10)||'BUDGET from '||v_TOT_BUDGET||' to '||v_PASS_BUDGET;
                      
                      SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                      SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                      dbms_output.put_line('6: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);    
                                          
                      IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693                  
                      
                              sql_stmt    :=   'UPDATE NBRPLBD SET NBRPLBD_PERCENT  = 0 , NBRPLBD_BUDGET = 0  ,  NBRPLBD_CHANGE_IND = ''D'' , NBRPLBD_BUDGET_TO_POST = ''0''' ||
                                          ' WHERE (nbrplbd_coas_code, nbrplbd_fund_code, nbrplbd_orgn_code, nbrplbd_acct_code, nbrplbd_prog_code) NOT IN '||
                                          '(select posn_coas_code, posn_fund_code, posn_orgn_code, posn_acct_code, posn_prog_code from '||
                                              'tt_hr_pass.nc_pass_transfunding_r  where '|| 
                                             ' nc_pass_trans_b_id = '||trans_b_rec.PASS_TRANS_ID||' ) '||
                                             ' and nbrplbd_posn = '''||trans_b_rec.PASS_POSN_NBR||''''||
                                             ' and nbrplbd_fisc_code = '||v_FISC_YEAR||' and nbrplbd_percent > 0';
                
                
                              DBMS_OUTPUT.PUT_LINE (v_comment||chr(10)||'CURSOR_DEL_PLBD QUERY: '||chr(10)||sql_stmt);
                
                              EXECUTE IMMEDIATE sql_stmt;
                      END IF;  --HPSS-1693        
                     
                      
                      select count(*) into v_NBRPTOT_COMMENT_CNT  FROM NBRPTOT
                      --FOR ONE POSITION NBRPTOT HAS ONLY ONE 'A' APPROVED RECORD FOR THAT FISCAL YEAR
                      WHERE  NBRPTOT_POSN = trans_b_rec.PASS_POSN_NBR
                      AND NBRPTOT_FISC_CODE = v_FISC_YEAR
                      AND NBRPTOT_STATUS IN ('A','W');
                      
                      IF(v_NBRPTOT_COMMENT_CNT > 0 ) THEN
                      
                          select  NBRPTOT_COMMENT into v_NBRPTOT_COMMENT FROM NBRPTOT
                          --FOR ONE POSITION NBRPTOT HAS ONLY ONE 'A' APPROVED RECORD FOR THAT FISCAL YEAR
                          WHERE  NBRPTOT_POSN = trans_b_rec.PASS_POSN_NBR
                          AND NBRPTOT_FISC_CODE = v_FISC_YEAR
                          AND NBRPTOT_STATUS IN ('A','W');
                          
                      ELSE
                      v_NBRPTOT_COMMENT := NULL;    
                      
                      END IF;
                     
                      --Update Pass Transaction No, Eff Date and Update Date on Transaction
                      DBMS_OUTPUT.PUT_LINE ('v_eff_date_char, v_date_char'||v_eff_date_char||' , '||v_date_char); 
                      SELECT TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY') into v_extract_year FROM dual;
                      SELECT TO_CHAR(to_date ('1-SEP-'||TO_CHAR(trans_b_rec.PASS_EFFECTIVE_DATE, 'YYYY')))  into v_extract_date FROM dual;
                                          
                      dbms_output.put_line('7: v_extract_year: '||v_extract_year||' v_extract_date: '||v_extract_date);    
                                          
                      IF( (v_FISC_YEAR > v_extract_year  ) OR 
                                                ( (trans_b_rec.PASS_EFFECTIVE_DATE < v_extract_date) and  (v_FISC_YEAR >=v_extract_year  ) ) ) then           --HPSS-1693           
                              
                              sql_stmt := 'UPDATE NBRPTOT SET ';
                              if trans_b_rec.PASS_COAS_CODE = 'E' then
                                    v_comment :=  v_NBRPTOT_COMMENT;
                              else
                                    v_comment := v_date_char||' PASS '||pass_trans_no||' with Eff Date '||v_eff_date_char;
                                    IF (trans_b_rec.PASS_FUTURE_VACANT = 'N') or (trans_b_rec.PASS_FUTURE_VACANT is null) then
                                      v_comment := v_comment||' '||v_EMP_RID||' '||v_EMP_FIRST_NAME||', '||v_EMP_LAST_NAME;
                                    end if;
                                      v_comment := v_comment||' Updated ';
                                    v_comment := fstringConcat(v_comment, v_add_comment);
                                    v_comment := fstringConcat(v_comment, v_NBRPTOT_COMMENT);
                              end if;      
        
                              v_comment := REPLACE(v_comment,'''', ''''' ');
                              DBMS_OUTPUT.PUT_LINE ('T NBRPTOT_COMMENT: '||v_comment); 
                              sql_stmt := sql_stmt||'NBRPTOT_COMMENT = '''||v_comment||''''||
                              '  where NBRPTOT_POSN = '''|| trans_b_rec.PASS_POSN_NBR ||''''||
                              '  AND NBRPTOT_FISC_CODE = '''|| v_FISC_YEAR ||''''||
                              '  AND NBRPTOT_STATUS IN (''A'' , ''W'') ' ;
                              --There will be only one A Approved record for one fiscal year and that alone needs to be updated
                              DBMS_OUTPUT.PUT_LINE ('Update Pass Transaction No, Eff Date and Update Date on Transaction: '||chr(10)||sql_stmt); 
                              EXECUTE IMMEDIATE sql_stmt; 
                       
                       END IF;  --HPSS-1693
                       
                       --hpss-1647 Update Comments NBRPLBD_CHANGE_IND = ''D'' if the fund has a 0 percent
                        sql_stmt := 'update nbrplbd  set NBRPLBD_CHANGE_IND = ''D''  where '||
                        ' nbrplbd_posn = '''|| trans_b_rec.PASS_POSN_NBR ||''''||' and nbrplbd_fisc_code = '''|| v_FISC_YEAR ||''''||' and nbrplbd_percent = 0';
                        EXECUTE IMMEDIATE sql_stmt; 
                         --hpss-1647 Update Comments NBRPLBD_CHANGE_IND = ''D'' if the fund has a 0 percent
                      
                END LOOP;
        EXIT WHEN CURSOR_DEL_PLBD%NOTFOUND;  
                
        END LOOP;
                 
      CLOSE CURSOR_DEL_PLBD;  
           
           
           --Updating transaction status to 'U' after position update
           IF (trans_b_rec.PASS_APPROVAL_DATE is not null)  then
            v_trans_status := 'C' ;
            DBMS_OUTPUT.PUT_LINE ('v_trans_status: '||v_trans_status||' Approval Date: '||trans_b_rec.PASS_APPROVAL_DATE); 
           ELSE
            DBMS_OUTPUT.PUT_LINE ('v_trans_status: '||v_trans_status||' Approval Date: '||trans_b_rec.PASS_APPROVAL_DATE); 
            v_trans_status := 'U';
           END IF;
           
           UPDATE TT_HR_PASS.NC_PASS_TRANS_B
           SET TRANS_STATUS =  v_trans_status   ,
               BNR_UPLOAD   = 'Y'
           WHERE TRANS_NO = pass_trans_no; 
           
           if  ( ( (trans_b_rec.PASS_COAS_CODE = 'S') AND  (v_trans_type = 'SR') ) OR ( (trans_b_rec.PASS_COAS_CODE = 'T')  AND  (v_trans_type = 'SR')  ) )  then
           
                 dbms_output.put_line('Transaction is  a Salary Review of Chart S or T');    
	
                           
           end if;
           --The Return Flag is Set to Success if the package is executed successfully
            rtn_flag := 'S';
           
       
        END IF;    --   IF ( ( (v_trans_type ='RC') OR (v_trans_type ='SR') ) AND (v_ep_flag = 'N') )THEN
        
        IF (v_ep_flag = 'Y') THEN
          rtn_flag := 'O'; --INDICATES THAT THIS TRANSACTION WILL BE UPLOADED ON THE NEXT PAID DATE   HPSS-1694
        END IF;
        
if utl_file.is_open (wfile_handle) then
  utl_file.fclose (wfile_handle);
  DBMS_OUTPUT.PUT_LINE ('File Closed : '||v_file||' rtn_flag: '||rtn_flag);
end if;


select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
   into   v_eprint_user
                from   dual;
   DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

    select gjbpseq.nextval
       into v_one_up
    from DUAL;

    GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
          ,'p_pass_banner_update'     -- e-Print Report definition (case sensitive)
          ,'p_pass_banner_update.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
          ,v_eprint_user            -- repository name
          ,v_eprint_user);          -- user id (same as repository name)
    DBMS_OUTPUT.PUT_LINE('Sending eprint report');
    DBMS_OUTPUT.PUT_LINE (' Completed.');    
    
EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                       ROLLBACK TO s_pass_update_banner;
                         --The Return Flag is Set to E if there's an Error
                         rtn_flag := 'E';
                         err_msg := ('ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                         DBMS_OUTPUT.PUT_LINE(err_msg);
                         /*v_file := 'p_pass_error.xls';
                         wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');  */
                         
                         /*err_msg := 'Process'||chr(9)||'p_rc_banner_upd';
                         utl_file.put_line(wfile_handle,err_msg);
                         err_msg := 'Transaction'||chr(9)||pass_trans_no;
                         utl_file.put_line(wfile_handle,err_msg);*/
                         
                         /*utl_file.put_line(wfile_handle,err_msg);
                         
                         if utl_file.is_open (wfile_handle) then
                           utl_file.fclose (wfile_handle);
                           DBMS_OUTPUT.PUT_LINE ('Err File Closed : '||v_file);
                         end if;
                         select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
                         into   v_eprint_user
                                      from   dual;
                         DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

                          select gjbpseq.nextval
                             into v_one_up
                          from DUAL;

                          GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
                                ,'p_pass_error'     -- e-Print Report definition (case sensitive)
                                ,'p_pass_error.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
                                ,v_eprint_user            -- repository name
                                ,v_eprint_user);          -- user id (same as repository name)
                          DBMS_OUTPUT.PUT_LINE('Sending eprint error report');
                          DBMS_OUTPUT.PUT_LINE (' Completed.'); 
                          */
                           insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','p_rc_banner_upd',
                          pass_trans_no,u_id
                          );


                     END;        
                                                                    
end;






 --------------------------------------------------------------------------------------------
-- OBJECT NAME: p_create_epaf      
-- PRODUCT....: HR
-- USAGE......: Create an EPFAF TRANSACTION for the PASS Application
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--  This procedure will create an EPAF TRANSACTION
-- based on the Reclassification / Salary Review Transaction Number provided in the PASS Application
--                                           
--------------------------------------------------------------------------------------------
PROCEDURE p_create_epaf(pass_trans_no IN varchar2,  u_id  IN varchar2,  rtn_flag OUT varchar2) is
wfile_handle                                                        utl_file.file_type;
v_one_up                                                            integer;
v_file                                                              varchar2 (300);
v_wstring                                                           varchar2 (6000);
v_eprint_user                                                       varchar2(90);
v_ptrcaln_start_date                                                date;
v_eff_date                                                          date;
v_date                                                              date;       
type r_FISC_YEAR                  IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.FISC_YEAR%TYPE;
type r_BUDGET_STATUS              IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_STATUS%TYPE;
type r_BUDGET_ID                  IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_ID%TYPE;
type r_BUDGET_PHASE               IS TABLE OF     TT_HR_PASS.NC_PASS_FISCYEAR_C.BUDG_PHASE%TYPE;
l_FISC_YEAR                                                         r_FISC_YEAR;
l_BUDGET_STATUS                                                     r_BUDGET_STATUS;
l_BUDGET_ID                                                         r_BUDGET_ID;
l_BUDGET_PHASE                                                      r_BUDGET_PHASE;
v_FISC_YEAR                                                         varchar2(4);
v_COMMENT                                                           varchar2(2000);
v_nbbposn_auth_number                                               NBBPOSN.NBBPOSN_AUTH_NUMBER%TYPE;
v_NBRPTOT_BUDGET                                                    NUMBER(11,2);
v_NBRPTOT_ANN_BASIS                                                 NBRPTOT.NBRPTOT_ANN_BASIS%TYPE;
v_NBRPTOT_BUDG_BASIS                                                NBRPTOT.NBRPTOT_BUDG_BASIS%TYPE;
v_NBRPTOT_BASE_UNITS                                                NBRPTOT.NBRPTOT_BASE_UNITS%TYPE;
sql_stmt                                                            VARCHAR2(2500);
v_RATE_OF_PAY                                                       TT_HR_PASS.NC_PASS_TRANS_B.POSN_RATE_OF_PAY%TYPE;
lcat_code                                                           PTRECLS.PTRECLS_LCAT_CODE%TYPE;
bcat_code                                                           PTRECLS.PTRECLS_BCAT_CODE%TYPE;
longevity_eligible                                                  boolean;
premium_pay_code                                                    varchar2(60);
--v_SUP_POSN                                                          NBRJOBS.NBRJOBS_SUPERVISOR_POSN%type;
--v_SUP_SUFF                                                          NBRJOBS.NBRJOBS_SUPERVISOR_SUFF%type;
v_PAY_TYPE                                                          varchar2(60);
fte_error                                                           boolean;
v_EXEMPT_IND                                                        NTRPCLS.NTRPCLS_EXEMPT_IND%type;
v_TIME_ENTRY_METHOD                                                 NBRJOBS.NBRJOBS_TIME_ENTRY_METHOD%type;
v_TCP_ORG_COUNT                                                     NUMBER;
v_BEGIN_DATE                                                        NBBPOSN.NBBPOSN_BEGIN_DATE%TYPE;
epaf_transaction_no                                                      nobtran.nobtran_transaction_no%type;
epaf_type                                                           nobtran.nobtran_acat_code%type;
v_originator_id                                                           varchar2(8);
v_SUP_ID                                                            spriden.spriden_id%type;
v_SUP_POSN                                                          NBRBJOB.NBRBJOB_POSN%type;  --HPSS-1714
v_SUP_SUFF                                                          NBRJOBS.nbrjobs_SUFF%type;  --HPSS-1714
field_value                                                         nortran.nortran_value%type;
hrs_day                                                             nbrjobs.NBRJOBS_HRS_DAY%type;
hrs_pay                                                             nbrjobs.NBRJOBS_HRS_PAY%type;
factor                                                              NBRPTOT.NBRPTOT_ANN_BASIS%type;
pays                                                                NBRPTOT.NBRPTOT_BASE_UNITS%type;
trans_type                                                          varchar2(20);
originator_first_name                                               SATURN.SPRIDEN.SPRIDEN_FIRST_NAME%TYPE;
originator_last_name                                                SATURN.SPRIDEN.SPRIDEN_LAST_NAME%TYPE;
v_NTRPCLS_SGRP_CODE                                                 POSNCTL.NTRPCLS.NTRPCLS_SGRP_CODE%TYPE;
v_NTRPCLS_Table                                                     POSNCTL.NTRPCLS.NTRPCLS_Table%type;
v_SUFF                                                              POSNCTL.NBRBJOB.NBRBJOB_SUFF%type;
v_norcmnt_sq                                                        NUMBER;
v_norcmnt_cmnt                                                      POSNCTL.NORCMNT.NORCMNT_COMMENTS%type;
v_timesheet_org                                                     POSNCTL.NBRJOBS.NBRJOBS_ORGN_CODE_TS%type;
v_ep_flag                                                           varchar2(1);       --HPSS-1694
v_holding_status                                                    varchar2(8);
v_trans_holding_posn_nbr                                            varchar2(6);
v_trans_holding_status                                              varchar2(2);
v_epaf_transaction_no                                               TT_HR_PASS.NC_PASS_TRANS_B.EPAF_TRANSACTION_NO%TYPE;
v_max_eff_date                                                      POSNCTL.NBRJOBS.NBRJOBS_EFFECTIVE_DATE%TYPE;-- nbrjobs_effective_date
v_jobs_ann_sal                                                      POSNCTL.NBRJOBS.nbrjobs_ann_salary%TYPE;
v_posn_sgrp_code                                                    POSNCTL.NBBPOSN.NBBPOSN_SGRP_CODE%TYPE;
v_posn_table                                                        POSNCTL.NBBPOSN.NBBPOSN_TABLE%TYPE; 
v_posn_grade                                                        POSNCTL.NBBPOSN.NBBPOSN_GRADE%TYPE;
v_curr_exempt_ind                                                   POSNCTL.NTRPCLS.NTRPCLS_EXEMPT_IND%TYPE;
v_new_exempt_ind                                                    POSNCTL.NTRPCLS.NTRPCLS_EXEMPT_IND%TYPE;
v_nbrjobs_hrs_pay                                                   POSNCTL.NBRJOBS.NBRJOBS_HRS_PAY%TYPE;-- nbrjobs_effective_date
v_ft_pt_ind_new                                                     varchar2(1);
v_ft_pt_ind_curr                                                    varchar2(1); 
v_CURR_ECLS_DESC                                                    PTRECLS.PTRECLS_LONG_DESC%TYPE; 
v_NEW_ECLS_DESC                                                     PTRECLS.PTRECLS_LONG_DESC%TYPE; 
v_JOBS_ASSGN_SALARY                                                 NBRJOBS.NBRJOBS_ASSGN_SALARY%TYPE;
v_JOBS_HRS_DAY                                                      NBRJOBS.NBRJOBS_HRS_DAY%TYPE;
v_JOBS_HRS_PAY                                                      NBRJOBS.NBRJOBS_HRS_PAY%TYPE;
v_NBRJOBS_PCAT_CODE                                                 NBRJOBS.NBRJOBS_PCAT_CODE%TYPE;
v_NBREARN_EARN_CODE_NEW                                             NBREARN.NBREARN_EARN_CODE%TYPE;
v_NBREARN_EARN_CODE_OLD                                             NBREARN.NBREARN_EARN_CODE%TYPE;
v_NBRJOBS_EMPR_CODE                                                 NBRJOBS.NBRJOBS_EMPR_CODE%TYPE;    --HPSS-1714
v_NBRJOBS_REG_RATE                                                  NBRJOBS.NBRJOBS_REG_RATE%TYPE;    --HPSS-1731
TYPE trans_b_rec_typ IS RECORD (
      TRANS_ID                 TT_HR_PASS.NC_PASS_TRANS_B.TRANS_ID%TYPE,
      
      BO_APPROVER              TT_HR_PASS.NC_PASS_TRANS_B.BO_APPROVER%TYPE,
      
      POSN_NBR                 TT_HR_PASS.NC_PASS_TRANS_B.POSN_NBR%TYPE,
      
      APPROVAL_DATE            TT_HR_PASS.NC_PASS_TRANS_B.APPROVAL_DATE%TYPE,
      
      POSN_EFFECTIVE_DATE      TT_HR_PASS.NC_PASS_TRANS_B.POSN_EFFECTIVE_DATE%TYPE,
      
      POSN_RATE_OF_PAY         TT_HR_PASS.NC_PASS_TRANS_B.POSN_RATE_OF_PAY%TYPE,
      
      POSN_FTE                 TT_HR_PASS.NC_PASS_TRANS_B.POSN_FTE%TYPE,
      
      POSN_COAS_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_COAS_CODE%TYPE, 
      
      POSN_SUPERVISOR_PIDM     TT_HR_PASS.NC_PASS_TRANS_B.POSN_SUPERVISOR_PIDM%TYPE, 
      
      POSN_PCLS_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_PCLS_CODE%TYPE,

      POSN_ORGN_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_ORGN_CODE%TYPE,
      
      POSN_CONTRACT_TYPE       TT_HR_PASS.NC_PASS_TRANS_B.POSN_CONTRACT_TYPE%TYPE,
      
      POSN_EXTENDED_TITLE      TT_HR_PASS.NC_PASS_TRANS_B.POSN_EXTENDED_TITLE%TYPE,
      
      JOB_CHANGE_REASON_CODE   TT_HR_PASS.NC_PASS_TRANS_B.JOB_CHANGE_REASON_CODE%TYPE,
      
      ORIGINATOR_PIDM          TT_HR_PASS.NC_PASS_TRANS_B.ORIGINATOR_PIDM%TYPE,
      
      POSN_ECLS_CODE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_ECLS_CODE%TYPE,
      
      CALC_EFF_DATE            TT_HR_PASS.NC_PASS_TRANS_B.CALC_EFF_DATE%TYPE,
      
      POSN_PAY_GRADE           TT_HR_PASS.NC_PASS_TRANS_B.POSN_PAY_GRADE%TYPE,
      
      PASS_PIDM                TT_HR_PASS.NC_PASS_TRANS_B.EMPLOYEE_PIDM%TYPE,
      
      PASS_CONTRACT_BEGIN_DATE   TT_HR_PASS.NC_PASS_TRANS_B.CONTRACT_BEGIN_DATE%TYPE,                                            
            
      PASS_CONTRACT_END_DATE     TT_HR_PASS.NC_PASS_TRANS_B.CONTRACT_END_DATE%TYPE,
      
      PASS_POSN_VACANT_BY_DATE   TT_HR_PASS.NC_PASS_TRANS_B.POSN_VACANT_BY_DATE%TYPE,
      
      PASS_LCAT_CODE             TT_HR_PASS.NC_PASS_TRANS_B.POSN_LCAT_CODE%TYPE,
      
      PASS_BCAT_CODE             TT_HR_PASS.NC_PASS_TRANS_B.POSN_BCAT_CODE%TYPE,
      
      PASS_SUFF                  TT_HR_PASS.NC_PASS_TRANS_B.CURR_POSN_SUFF%TYPE,  
      
      CURR_ECLS_CODE             TT_HR_PASS.NC_PASS_TRANS_B.CURR_ECLS_CODE%TYPE,
      
      CURR_PCLS_CODE             TT_HR_PASS.NC_PASS_TRANS_B.CURR_PCLS_CODE%TYPE,
      
      POSN_PICT_CODE             TT_HR_PASS.NC_PASS_TRANS_B.POSN_PICT_CODE%TYPE,
      
      FUTURE_VACANT              TT_HR_PASS.NC_PASS_TRANS_B.FUTURE_VACANT%TYPE,
      
      BNR_UPLOAD                 TT_HR_PASS.NC_PASS_TRANS_B.BNR_UPLOAD%TYPE,
      
      CURR_POSN_FTE              TT_HR_PASS.NC_PASS_TRANS_B.CURR_POSN_FTE%TYPE   );
trans_b_rec trans_b_rec_typ;

TYPE ptrecls_rec_typ IS RECORD (
       PTRECLS_PICT_CODE               PTRECLS.PTRECLS_PICT_CODE%type,
       PTRECLS_INTERNAL_FT_PT_IND      PTRECLS.PTRECLS_INTERNAL_FT_PT_IND%TYPE
      );
ptrecls_rec ptrecls_rec_typ;

TYPE nortran_rec_typ IS RECORD (
ntvacat_code              ntvacat.ntvacat_code%type,
ntvacat_desc              ntvacat.ntvacat_desc%type,
ntracat_acat_code         ntracat.ntracat_acat_code%type,
ntracat_apty_code         ntracat.ntracat_apty_code%type,
ntvapty_desc              ntvapty.ntvapty_desc%type,
ntrapfd_aufm_code         ntrapfd.ntrapfd_aufm_code%type,
ntrapfd_aubk_code         ntrapfd.ntrapfd_aubk_code%type,
ntrapfd_aufd_code         ntrapfd.ntrapfd_aufd_code%type,
ntrapfd_required_ind      ntrapfd.ntrapfd_required_ind%type,
NTRADFV_AUFM_CODE         NTRADFV.NTRADFV_AUFM_CODE%type,
NTRADFV_AUFD_CODE         NTRADFV.NTRADFV_AUFD_CODE%type,
NTRADFV_AUFD_DEFAULT      NTRADFV.NTRADFV_AUFD_DEFAULT%type,
NTRAPFD_DISPLAY_SEQ_NO    NTRAPFD.NTRAPFD_DISPLAY_SEQ_NO%type,
NTRADFV_DEFAULT_OVERRIDE_IND     NTRADFV.NTRADFV_DEFAULT_OVERRIDE_IND%type);
nortran_rec nortran_rec_typ;

TYPE norrout_rec_typ IS RECORD (
ntraclv_acat_code                  POSNCTL.ntraclv.ntraclv_acat_code%type,
ntraclv_alvl_code                  POSNCTL.ntraclv.ntraclv_alvl_code%type,
ntraclv_action_ind                 POSNCTL.ntraclv.ntraclv_action_ind%type,
ntralvl_level                      POSNCTL.ntralvl.ntralvl_level%type, 
ntralvl_superuser_ind              POSNCTL.ntralvl.ntralvl_superuser_ind%type,
ntrlvid_user_id                    POSNCTL.ntrlvid.ntrlvid_user_id%type
);
norrout_rec  norrout_rec_typ;

TYPE transfunding_rec_typ IS RECORD (
PASS_POSN_FUND_CODE                        tt_hr_pass.nc_pass_transfunding_r.POSN_FUND_CODE%type,
POSN_ORGN_CODE                             tt_hr_pass.nc_pass_transfunding_r.POSN_ORGN_CODE%type,
POSN_ACCT_CODE                             tt_hr_pass.nc_pass_transfunding_r.POSN_ACCT_CODE%type,
POSN_PROG_CODE                             tt_hr_pass.nc_pass_transfunding_r.POSN_PROG_CODE%type, 
POSN_CURRENT_ACCT_PERCENT                  tt_hr_pass.nc_pass_transfunding_r.POSN_CURRENT_ACCT_PERCENT%type
);
transfunding_rec  transfunding_rec_typ;

TYPE jobs_rec_typ IS RECORD (
JOBS_ORGN_CODE_TS                   NBRJOBS.NBRJOBS_ORGN_CODE_TS%type,
JOBS_SHIFT                          NBRJOBS.NBRJOBS_SHIFT%type,
JOBS_FACTOR                         NBRJOBS.NBRJOBS_FACTOR%type,
JOBS_PAYS                           NBRJOBS.NBRJOBS_PAYS%type,
JOBS_TIME_ENTRY_METHOD              NBRJOBS.NBRJOBS_TIME_ENTRY_METHOD%type,
JOBS_TIME_ENTRY_TYPE                NBRJOBS.NBRJOBS_TIME_ENTRY_TYPE%type,
JOBS_TIME_IN_OUT_IND                NBRJOBS.NBRJOBS_TIME_IN_OUT_IND%type,
JOBS_LEAV_REPT_METHOD               NBRJOBS.NBRJOBS_LEAV_REPT_METHOD%type,
JOBS_PICT_CODE_LEAV_REPT            NBRJOBS.NBRJOBS_PICT_CODE_LEAV_REPT%type,
JOBS_HRS_DAY                        NBRJOBS.NBRJOBS_HRS_DAY%type,
JOBS_ASSGN_SALARY                   NBRJOBS.NBRJOBS_ASSGN_SALARY%type,
JOBS_PER_PAY_SALARY                 NBRJOBS.NBRJOBS_PER_PAY_SALARY%type,
JOBS_PCAT_CODE                      NBRJOBS.NBRJOBS_PCAT_CODE%type,
JOBS_EMPR_CODE                      NBRJOBS.NBRJOBS_EMPR_CODE%type
);
jobs_rec   jobs_rec_typ;
   
CURSOR nortran_field(p_epaf_type IN varchar2)  IS
select iv1.ntvacat_code, iv1.ntvacat_desc, iv1.ntracat_acat_code,iv1.ntracat_apty_code, iv1.ntvapty_desc,
iv1.ntrapfd_aufm_code, iv1.ntrapfd_aubk_code, iv1.ntrapfd_aufd_code, iv1.ntrapfd_required_ind,
NTRADFV_AUFM_CODE,NTRADFV_AUFD_CODE,NTRADFV_AUFD_DEFAULT, NTRAPFD_DISPLAY_SEQ_NO, NTRADFV_DEFAULT_OVERRIDE_IND
from
(select distinct ntvacat_code, ntvacat_desc,ntracat_acat_code, ntracat_apty_code,ntvapty_code, ntvapty_desc,
ntrapfd_aufm_code, ntrapfd_aubk_code, ntrapfd_aufd_code, NTRAPFD_DISPLAY_SEQ_NO, ntrapfd_required_ind from
ntvacat, ntracat, ntvapty, ntrapfd, ntradfv
where ntvacat_code = ntracat_acat_code
  and ntracat_apty_code = ntvapty_code
  and ntrapfd_apty_code = ntracat_apty_code
  and ntvacat_code = p_epaf_type
  and ntracat_apty_code NOT IN ('EARN', 'LABOR')
  ) iv1
left outer join ntradfv ON
  iv1.ntracat_acat_code = ntradfv_acat_code
  and iv1.ntracat_apty_code = ntradfv_apty_code
  and iv1.ntrapfd_aufm_code = ntradfv_aufm_code
  and iv1.ntrapfd_aubk_code = ntradfv_aubk_code
  and iv1.ntrapfd_aufd_code = ntradfv_aufd_code
order by ntracat_acat_code, ntracat_apty_code;  

CURSOR norrout_field(p_epaf_type IN varchar2)  IS
select ntraclv_acat_code, ntraclv_alvl_code, ntraclv_action_ind,
ntralvl_level, ntralvl_superuser_ind, ntrlvid_user_id
from ntraclv, ntralvl, ntrlvid
where ntraclv_acat_code = p_epaf_type
and ntraclv_alvl_code= ntralvl_code
and ntrlvid_alvl_code = ntraclv_alvl_code
and ntrlvid_inactive_ind = 'N'
and ntralvl_level NOT IN (20, 73);

--This cursor is used to fetch the values of Fund code, Orgn Code, Acct Code,  Prog Code and Current Account Percent from PASS
--This is used for updating NORTLBD
CURSOR transfunding_field(p_trans_no IN varchar2)  IS
select transf.POSN_FUND_CODE, transf.POSN_ORGN_CODE, transf.POSN_ACCT_CODE, transf.POSN_PROG_CODE, transf.POSN_PROPOSED_ACCT_PERCENT
from tt_hr_pass.nc_pass_transfunding_r transf, tt_hr_pass.nc_pass_trans_b trans_b
where transf.NC_PASS_TRANS_B_ID = trans_b.TRANS_ID
and   trans_b.TRANS_NO = p_trans_no
and transf.POSN_PROPOSED_ACCT_PERCENT > 0;

BEGIN
        
        savepoint s_pass_create_epaf;        
      
        v_file := 'p_pass_banner_update.xls';
        wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');
        
        select sysdate into v_date from dual;
        
         --1. Open NC_PASS_TRANS_B Record        
        SELECT TRANS_ID, BO_APPROVER, POSN_NBR, APPROVAL_DATE, POSN_EFFECTIVE_DATE,
        POSN_RATE_OF_PAY,  POSN_FTE, POSN_COAS_CODE, POSN_SUPERVISOR_PIDM,
        POSN_PCLS_CODE,   POSN_ORGN_CODE, POSN_CONTRACT_TYPE,
        POSN_EXTENDED_TITLE,JOB_CHANGE_REASON_CODE, ORIGINATOR_PIDM, POSN_ECLS_CODE, 
        CALC_EFF_DATE, POSN_PAY_GRADE, EMPLOYEE_PIDM,  CONTRACT_BEGIN_DATE,  CONTRACT_END_DATE, POSN_VACANT_BY_DATE, 
        POSN_LCAT_CODE , POSN_BCAT_CODE , CURR_POSN_SUFF, CURR_ECLS_CODE, CURR_PCLS_CODE, POSN_PICT_CODE, 
        FUTURE_VACANT, BNR_UPLOAD, CURR_POSN_FTE
        into   trans_b_rec
        FROM  TT_HR_PASS.NC_PASS_TRANS_B
        WHERE  TT_HR_PASS.NC_PASS_TRANS_B.TRANS_NO = pass_trans_no
        --AND TT_HR_PASS.NC_PASS_TRANS_B.TRANS_STATUS = 'U'
         AND (  (TT_HR_PASS.NC_PASS_TRANS_B.FUTURE_VACANT <> 'Y')   or   (TT_HR_PASS.NC_PASS_TRANS_B.FUTURE_VACANT is null)  ); 
        
        select max(nbrjobs_effective_date) INTO  v_max_eff_date
        from  nbrjobs 
        where nbrjobs_posn = trans_b_rec.POSN_NBR
        and   nbrjobs_pidm = trans_b_rec.PASS_PIDM
        and   NBRJOBS_SUFF = trans_b_rec.PASS_SUFF
        and nbrjobs_status = 'A';
        
        --HPSS-1714
        select NBRBJOB_POSN,nbrjobs_SUFF  INTO  v_SUP_POSN, v_SUP_SUFF
        from NBRBJOB,NBRJOBS T1
        WHERE NBRBJOB_PIDM = trans_b_rec.POSN_SUPERVISOR_PIDM
        and nbrbjob_contract_type = 'P'  
        and ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
                           
        and t1.nbrjobs_pidm = nbrbjob_pidm
        AND T1.NBRJOBS_POSN = NBRBJOB_POSN
        and t1.nbrjobs_SUFF = NBRBJOB_SUFF
                           
        AND T1.NBRJOBS_STATUS != 'T'        --HPSS-1744  
                           
        AND T1.NBRJOBS_EFFECTIVE_DATE =
        (SELECT MAX(NBRJOBS_EFFECTIVE_DATE)
        FROM NBRJOBS T11
        WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
        AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
        AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
        AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE)  ;
        
        
        select NBBPOSN_SGRP_CODE, NBBPOSN_TABLE, NBBPOSN_GRADE
        into v_posn_sgrp_code,v_posn_table, v_posn_grade
        from nbbposn where nbbposn_posn = trans_b_rec.POSN_NBR;
        
        dbms_output.put_line('v_max_eff_date: '||v_max_eff_date||' pass_trans_no: '||pass_trans_no||' v_SUP_POSN: '||v_SUP_POSN||' v_SUP_SUFF: '||v_SUP_SUFF);
        
        select sum(POSN_PROPOSED_ANNUAL_FOAP_AMT) 
        into v_jobs_ann_sal
        from tt_hr_pass.nc_pass_transfunding_R f, tt_hr_pass.nc_pass_trans_b b
        where f.NC_PASS_TRANS_B_ID = b.TRANS_ID
        and b.TRANS_NO = pass_trans_no;
        
        v_JOBS_HRS_PAY := ROUND((86.67 * trans_b_rec.POSN_FTE),2);
        
        
        select NTRPCLS_EXEMPT_IND into v_curr_exempt_ind
        from ntrpcls where NTRPCLS_CODE = trans_b_rec.CURR_PCLS_CODE; 
        
        select NTRPCLS_EXEMPT_IND into v_new_exempt_ind
        from ntrpcls where NTRPCLS_CODE = trans_b_rec.POSN_PCLS_CODE;
        
        v_ep_flag := getElPasoEPAFFlag(pass_trans_no,  trans_b_rec.POSN_COAS_CODE, trans_b_rec.PASS_PIDM, trans_b_rec.FUTURE_VACANT, trans_b_rec.APPROVAL_DATE,
        trans_b_rec.BNR_UPLOAD, trans_b_rec.CALC_EFF_DATE );
        
        --Get PT to FT or FT to PT HPSS-1679
        select PTRECLS_INTERNAL_FT_PT_IND into v_ft_pt_ind_curr from ptrecls where PTRECLS_CODE = trans_b_rec.CURR_ECLS_CODE ;
        select PTRECLS_INTERNAL_FT_PT_IND into v_ft_pt_ind_new   from ptrecls where PTRECLS_CODE = trans_b_rec.POSN_ECLS_CODE ;
        v_NBRJOBS_PCAT_CODE := NULL; 
        IF ( (v_ft_pt_ind_new = 'F' ) AND (v_ft_pt_ind_curr = 'P') ) THEN 

        	v_NBREARN_EARN_CODE_NEW := 'HLD';
        	v_NBREARN_EARN_CODE_OLD := 'HLN';
          v_NBRJOBS_PCAT_CODE := 'LONG'; 
        
                                  
        ELSIF ( (v_ft_pt_ind_new = 'P' ) AND (v_ft_pt_ind_curr = 'F') ) THEN                    
        	
        	v_NBREARN_EARN_CODE_NEW := 'HLN';
        	v_NBREARN_EARN_CODE_OLD := 'HLD';
                  
        ELSIF ( (v_ft_pt_ind_new = 'P' ) AND (v_ft_pt_ind_curr = 'P') ) THEN     
        	
        	v_NBREARN_EARN_CODE_NEW := 'HLN';  
          
        ELSIF ( (v_ft_pt_ind_new = 'F' ) AND (v_ft_pt_ind_curr = 'F') ) THEN 
        
          v_NBREARN_EARN_CODE_NEW := 'HLD'; 
          v_NBRJOBS_PCAT_CODE := 'LONG';                        
        
        END IF;
        IF (trans_b_rec.POSN_PCLS_CODE = 'S1801') OR (trans_b_rec.POSN_PCLS_CODE = 'S1802') OR (trans_b_rec.POSN_PCLS_CODE = 'S1803') OR (trans_b_rec.POSN_PCLS_CODE = 'S1804') OR 
                      (trans_b_rec.POSN_PCLS_CODE = 'S1805') OR (trans_b_rec.POSN_PCLS_CODE = 'S1806') OR (trans_b_rec.POSN_PCLS_CODE = 'S1807') OR (trans_b_rec.POSN_PCLS_CODE = 'S1808') OR (trans_b_rec.POSN_PCLS_CODE = 'S1809') THEN
                         v_NBRJOBS_PCAT_CODE   := 'HAZ' ;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE ('v_ep_flag: '||v_ep_flag||' Position Full/Part Time Indicator: '||v_ft_pt_ind_new ||' Current Position Full/Part Time Indicator: '||v_ft_pt_ind_curr||
        ' v_NBREARN_EARN_CODE_NEW: '||v_NBREARN_EARN_CODE_NEW ||' v_NBREARN_EARN_CODE_OLD: '||v_NBREARN_EARN_CODE_OLD);
        
--        --CREATE EPAF IF POSITION IS NOT VACANT
        IF ( (trans_b_rec.PASS_PIDM IS NOT NULL) AND (v_new_exempt_ind = v_curr_exempt_ind)  AND (v_ep_flag = 'N') AND (trans_b_rec.CURR_POSN_FTE = trans_b_rec.POSN_FTE) ) THEN 
        --END IF;-- IF ( (trans_b_rec.PASS_PIDM IS NOT NULL) AND (v_new_exempt_ind = v_curr_exempt_ind)  AND (v_ep_flag = 'N') ) THEN
        
                    v_nbbposn_auth_number  := 'PASS '||nvl(trans_b_rec.BO_APPROVER, '');
                    
                    DBMS_OUTPUT.PUT_LINE (chr(10)||'Trans No: ' || pass_trans_no||' Date: '||v_date||' v_nbbposn_auth_number: '||v_nbbposn_auth_number||
                                              ' trans_b_rec.BO_APPROVER: '||trans_b_rec.BO_APPROVER||' trans_b_rec.POSN_NBR: '||chr(9)||trans_b_rec.POSN_NBR||chr(10));
                    
                    --1.2. GET PTRECLS_PICT_CODE, PTRECLS_INTERNAL_FT_PT_IND  and NBBPOSN_BEGIN_DATE
                            
                    SELECT  PTRECLS_PICT_CODE, PTRECLS_INTERNAL_FT_PT_IND
                    INTO ptrecls_rec FROM PTRECLS
                    WHERE PTRECLS_CODE = trans_b_rec.POSN_ECLS_CODE;
                    
                    select nbrbjob_begin_date into v_BEGIN_DATE from nbrbjob
                    where nbrbjob_posn  =   trans_b_rec.POSN_NBR
                    and nbrbjob_pidm    =   trans_b_rec.PASS_PIDM
                    and nbrbjob_suff    =   trans_b_rec.PASS_SUFF
                    and ((nbrbjob_end_date is null) or (nbrbjob_end_date > sysdate)); 
                    
                                                                                       
                    --1.3. CALCULATE EFFECTIVE DATE
                    if      (SUBSTR(pass_trans_no,0,2)) = 'RC'  then
                         trans_type :=  'RECLASSIFICATION';
                         v_eff_date := trans_b_rec.CALC_EFF_DATE;
                         
                         elsif(SUBSTR(pass_trans_no,0,2))  = 'SR'  then
                         trans_type :=  'SALARY REVIEW';
                         
                         --Calculate & Update effective date for Salary Review Transaction
                         v_eff_date :=  getCalcEffDate(ptrecls_rec.PTRECLS_PICT_CODE, v_date,  trans_b_rec.POSN_EFFECTIVE_DATE);
                         
                         update tt_hr_pass.nc_pass_trans_b
                         set  CALC_EFF_DATE = v_eff_date
                         where TRANS_NO =  pass_trans_no;
                           
                    end if;
                    
                  
                    
                    v_wstring := 'TRANSACTION'||chr(9)||'EPAF FOR '||trans_type;
                    utl_file.put_line(wfile_handle,v_wstring);
                    DBMS_OUTPUT.PUT_LINE (v_wstring);

                    v_wstring := ' PASS TRANSACTION NUMBER'||chr(9)||pass_trans_no;
                    utl_file.put_line(wfile_handle,v_wstring);
                    DBMS_OUTPUT.PUT_LINE (v_wstring);
                    
                    v_wstring := 'DATE'||chr(9)||v_date;
                    utl_file.put_line(wfile_handle,v_wstring);
                    DBMS_OUTPUT.PUT_LINE (v_wstring);     
                    
                    DBMS_OUTPUT.PUT_LINE (chr(10)||'v_date : ' || v_eff_date||chr(10));
                       
                       --DETERMINE PAY TYPE BASED ON PICT CODE
                      IF(ptrecls_rec.PTRECLS_PICT_CODE = 'MN') THEN
                        
                        v_RATE_OF_PAY := trans_b_rec.POSN_RATE_OF_PAY;
                        v_PAY_TYPE :=   'NBRJOBS_ANN_SALARY';
                        
                        ELSIF(ptrecls_rec.PTRECLS_PICT_CODE = 'SM') THEN
                        --v_RATE_OF_PAY := trans_b_rec.POSN_FTE * trans_b_rec.POSN_RATE_OF_PAY *2080.08;
                        v_RATE_OF_PAY := trans_b_rec.POSN_RATE_OF_PAY;
                        v_PAY_TYPE := 'NBRJOBS_REG_RATE' ;
                      
                      END IF;
                      
                      SELECT NTRPCLS_EXEMPT_IND, NTRPCLS_SGRP_CODE,  NTRPCLS_Table into v_EXEMPT_IND, v_NTRPCLS_SGRP_CODE,  v_NTRPCLS_Table  from NTRPCLS
                      WHERE NTRPCLS_CODE = trans_b_rec.POSN_PCLS_CODE;

                      case
                      when v_EXEMPT_IND = 'Y' then
                      v_TIME_ENTRY_METHOD := 'P';

                      WHEN v_EXEMPT_IND = 'N' then
                      SELECT COUNT(*) 
                      INTO v_TCP_ORG_COUNT 
                      FROM TTUFISCAL.PWRTCPC 
                      where PWRTCPC_COAS_CODE = trans_b_rec.POSN_COAS_CODE
                      and PWRTCPC_ORGN_CODE_TS like trans_b_rec.POSN_ORGN_CODE;
                      
                           if v_TCP_ORG_COUNT > 0 then
                           v_TIME_ENTRY_METHOD := 'T';
                           else
                           v_TIME_ENTRY_METHOD := 'W';
                           end if; 
                           
                      
                      end case;
                      
                          --Get ACAT Code based on chart, transaction type and Exempt Indicator
                          --chart H epaf codes
                          IF  ( (trans_b_rec.POSN_COAS_CODE = 'H') and (trans_type = 'RECLASSIFICATION') and (v_EXEMPT_IND = 'Y' ) ) then 
                                epaf_type := 'PHRCE';
                                
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'H') and (trans_type = 'RECLASSIFICATION') and (v_EXEMPT_IND = 'N' ) ) then 
                                epaf_type := 'PHRCN';
                                
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'H') and (trans_type = 'SALARY REVIEW') and (v_EXEMPT_IND = 'Y' ) ) then 
                                epaf_type := 'PHSRE';
                                
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'H') and (trans_type = 'SALARY REVIEW') and (v_EXEMPT_IND = 'N' ) ) then 
                                epaf_type := 'PHSRN'; 
                                
                                --char E epaf codes
                                /*
                                EPEXP ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Exempt ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ El Paso - PASS
                                EPNEP ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Non-Exempt ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ El Paso - PASS

                                */
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'E') and (trans_type = 'RECLASSIFICATION') and (v_EXEMPT_IND = 'Y' ) ) then 
                                epaf_type :='EPREXP';  --HPSS-1699
                                
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'E') and (trans_type = 'RECLASSIFICATION') and (v_EXEMPT_IND = 'N' ) ) then 
                                epaf_type := 'EPRNEP';  --HPSS-1699
                                
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'E') and (trans_type = 'SALARY REVIEW') and (v_EXEMPT_IND = 'Y' ) ) then 
                                epaf_type := 'EPSREP';
                                
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'E') and (trans_type = 'SALARY REVIEW') and (v_EXEMPT_IND = 'N' ) ) then 
                                epaf_type := 'EPSRNP'; 
                                
                                --char T epaf codes
                                --9  month faculty reclass
                                ELSIF ( (trans_b_rec.POSN_COAS_CODE = 'T') and (trans_type = 'RECLASSIFICATION') and trans_b_rec.POSN_ECLS_CODE IN ('F1', 'F2', 'F3', 'F4') ) then 
                                epaf_type := 'TPRCF';
                                
                                ELSIF ( ((trans_b_rec.POSN_COAS_CODE = 'T') or (trans_b_rec.POSN_COAS_CODE = 'S')) and (trans_type = 'RECLASSIFICATION') and (v_EXEMPT_IND = 'Y' ) ) then 
                                epaf_type := 'TPRCE';
                                
                                ELSIF ( ((trans_b_rec.POSN_COAS_CODE = 'T') or (trans_b_rec.POSN_COAS_CODE = 'S')) and (trans_type = 'RECLASSIFICATION') and (v_EXEMPT_IND = 'N' ) ) then 
                                epaf_type := 'TPRCNE';
                                
                                --ELSIF ( trans_b_rec.POSN_COAS_CODE = 'E' )   and (trans_type = 'RECLASSIFICATION')  THEN 
                                --epaf_type := 'EPRCP';   
                
                               --ELSIF  ( (trans_b_rec.POSN_COAS_CODE = 'S')  and ((trans_type = 'SALARY REVIEW') ) ) then  
                               --epaf_type := 'HPACHE';        
                          
                          end if;  
                          
                          v_wstring := 'CHART'||chr(9)||trans_b_rec.POSN_COAS_CODE;
                          utl_file.put_line(wfile_handle,v_wstring);
                          DBMS_OUTPUT.PUT_LINE (v_wstring); 
                          v_wstring := 'EPAF TYPE'||chr(9)||epaf_type;
                          utl_file.put_line(wfile_handle,v_wstring);
                          DBMS_OUTPUT.PUT_LINE (v_wstring); 

            IF trans_b_rec.POSN_FTE < 0.00 OR trans_b_rec.POSN_FTE > 1.00 THEN
                 fte_error  := true;
            end if; 

            CASE
               WHEN trans_b_rec.POSN_ECLS_CODE IN ('F2', 'F3') then

                   if fte_error then
                      hrs_pay := 0.00;
                   else
                      hrs_pay := 173.33 * trans_b_rec.POSN_FTE;
                   end if;
                   
               WHEN trans_b_rec.POSN_ECLS_CODE IN ('N0', 'N1', 'N6', 'N7', 'S1', 'S4', 'S6') then

                   if fte_error then
                      hrs_pay := 0.00;
                   else
                      hrs_pay := 86.67 * trans_b_rec.POSN_FTE;
                   end if;
                   
               WHEN trans_b_rec.POSN_ECLS_CODE IN ('F1', 'F4') then

                   if fte_error then
                      hrs_pay := 0.00;
                   else
                      hrs_pay := 173.33 * trans_b_rec.POSN_FTE;
                   end if;
                   
               WHEN trans_b_rec.POSN_ECLS_CODE = 'S2' then
                   
                   if trans_b_rec.POSN_PCLS_CODE IN ('U0325', 'U0324' ) then  --GET FTE_ERROR

                      if fte_error then
                         hrs_pay := 0.00;
                      else
                         hrs_pay := 173.33 * trans_b_rec.POSN_FTE;
                      end if;
                      
                   else
                      if fte_error then
                         hrs_pay := 0.00;
                      else
                         hrs_pay := 173.33 * trans_b_rec.POSN_FTE;
                      end if;
                      
                   end if;
                   
               ELSE

                   if fte_error then
                      hrs_pay := 0.00;
                   else
                      hrs_pay := 173.33 * trans_b_rec.POSN_FTE;
                   end if;

            END CASE;   

            -- Determine Factor and pays
            CASE
               WHEN trans_b_rec.POSN_ECLS_CODE IN ('F2', 'F3') then
                   factor := 11;
                   pays   := 11;
                   if fte_error then
                      hrs_day := 0.00;
                      hrs_day := 0.00;
                   else
                      hrs_day := 8 * trans_b_rec.POSN_FTE ;
                      hrs_pay := 173.33 * trans_b_rec.POSN_FTE ;
                   end if;
               WHEN trans_b_rec.POSN_ECLS_CODE IN ('N0', 'N1', 'N6', 'N7', 'S1', 'S4', 'S6') then
                   factor := 24;
                   pays   := 24;
                   if fte_error then
                      hrs_day := 0.00;
                      hrs_day := 0.00;
                   else
                      hrs_day := 8 * trans_b_rec.POSN_FTE ;
                      hrs_pay := 86.67 * trans_b_rec.POSN_FTE ;
                   end if;
               WHEN trans_b_rec.POSN_ECLS_CODE IN ('F1', 'F4') then
                   factor := 9;
                   pays   := 9;
                   if fte_error then
                      hrs_day := 0.00;
                      hrs_day := 0.00;
                   else
                      hrs_day := 8 * trans_b_rec.POSN_FTE ;
                      hrs_pay := 173.33 * trans_b_rec.POSN_FTE ;
                   end if;
               WHEN trans_b_rec.POSN_ECLS_CODE = 'S2' then
                   if trans_b_rec.POSN_PCLS_CODE IN ('U0325', 'U0324' ) then
                      factor := 9;
                      pays   := 9;
                      if fte_error then
                         hrs_day := 0.00;
                         hrs_day := 0.00;
                      else
                         hrs_day := 8 * trans_b_rec.POSN_FTE ;
                         hrs_pay := 173.33 * trans_b_rec.POSN_FTE ;
                      end if;
                   else
                      factor := 12;
                      pays   := 12;
                      if fte_error then
                         hrs_day := 0.00;
                         hrs_day := 0.00;
                      else
                         hrs_day := 8 * trans_b_rec.POSN_FTE ;
                         hrs_pay := 173.33 * trans_b_rec.POSN_FTE ;
                      end if;
                   end if;
               ELSE
                   factor := 12;
                   pays   := 12;
                   if fte_error then
                      hrs_day := 0.00;
                      hrs_day := 0.00;
                   else
                      hrs_day := 8 * trans_b_rec.POSN_FTE ;
                      hrs_pay := 173.33 * trans_b_rec.POSN_FTE ;
                   end if;

            END CASE;

            longevity_eligible := false;
            if (trans_b_rec.POSN_ECLS_CODE like 'E%' or trans_b_rec.POSN_ECLS_CODE like 'N%') and trans_b_rec.POSN_FTE = 1.0 then
                longevity_eligible := true;
            end if;

            if longevity_eligible then
               premium_pay_code := 'LONG';
            else
               premium_pay_code := null;
            end if; 

            --Get NBRBJOB SUFFIX FOR PRIMARY POSITION v_SUFF

            select NBRBJOB_SUFF, NBRJOBS_ORGN_CODE_TS INTO v_SUFF,v_timesheet_org  from
            NBRBJOB,NBRJOBS T1
              WHERE  
                   NBRBJOB_PIDM = trans_b_rec.PASS_PIDM
                   and NBRBJOB_POSN = trans_b_rec.POSN_NBR
                   and nbrbjob_contract_type = 'P'  
                   and ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
                   
                   and t1.nbrjobs_pidm = nbrbjob_pidm
                   AND T1.NBRJOBS_POSN = NBRBJOB_POSN
                   and t1.nbrjobs_SUFF = NBRBJOB_SUFF
                   
                   AND T1.NBRJOBS_STATUS = 'A'          
                   
                   AND T1.NBRJOBS_EFFECTIVE_DATE =
                          (SELECT MAX(NBRJOBS_EFFECTIVE_DATE)
                             FROM NBRJOBS T11
                            WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                                  AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                                  AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                                  AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE) ;


            epaf_transaction_no := getEpafTransNo();

            select spriden_id into v_SUP_ID from spriden where spriden_pidm = trans_b_rec.POSN_SUPERVISOR_PIDM  and SPRIDEN_CHANGE_IND is null;

            select GWVAUTH_ORACLE_ID into v_originator_id  from tt_acct_security.gwvauth where GWVAUTH_PIDM = trans_b_rec.ORIGINATOR_PIDM;

            select   SPRIDEN.SPRIDEN_FIRST_NAME,   SPRIDEN.SPRIDEN_LAST_NAME into  originator_first_name, originator_last_name
            from SPRIDEN
            where SPRIDEN_PIDM = trans_b_rec.ORIGINATOR_PIDM  and SPRIDEN_CHANGE_IND is null;

                          v_wstring := 'Originator Name'||chr(9)||originator_first_name||' '||originator_last_name;
                          utl_file.put_line(wfile_handle,v_wstring);
                          DBMS_OUTPUT.PUT_LINE (v_wstring); 


                                                                                   
                      dbms_output.put_line(chr(10)||
                      'CHART: '||trans_b_rec.POSN_COAS_CODE||chr(10)|| 
                      'pcls_code: '||trans_b_rec.POSN_PCLS_CODE||chr(10)||
                      'PEBEMPL_ECLS_CODE = NBRJOBS_ECLS_CODE = '||trans_b_rec.POSN_ECLS_CODE||chr(10)||
                      'PEBEMPL_INTERNAL_FT_PT_IND: '||ptrecls_rec.PTRECLS_INTERNAL_FT_PT_IND||chr(10)||
                      'NBRJOBS_FTE: '||trans_b_rec.POSN_FTE||chr(10)||
                      'NBRJOBS_STATUS: A'||chr(10)||
                      'NBRBJOB_BEGIN_DATE: '||v_BEGIN_DATE||chr(10)||
                      'NBRJOBS_EFFECTIVE_DATE = NBRJOBS_PERS_CHG_DATE '||v_eff_date||chr(10)||
                      'NBRBJOB_CONTRACT_TYPE: P'||chr(10)||
                      'NBRJOBS_TIME_ENTRY_METHOD: '||v_TIME_ENTRY_METHOD||chr(10)||
                      'PEBEMPL_EMPL_STATUS: A'||chr(10)||
                      v_PAY_TYPE||': '||v_RATE_OF_PAY||chr(10)||
                      'FTE: '||trans_b_rec.POSN_FTE||chr(10)||
                      'lcat_code: '||trans_b_rec.PASS_LCAT_CODE||chr(10)||
                      'bcat_code: '||trans_b_rec.PASS_BCAT_CODE||chr(10)||
                      'NBRBJOB_CONTRACT_TYPE: '||trans_b_rec.POSN_CONTRACT_TYPE||chr(10)||
                      'NBRJOBS_DESC: '||trans_b_rec.POSN_EXTENDED_TITLE||chr(10)||
                      'NBRJOBS_SAL_STEP: 0'||chr(10)||
                      'NBRJOBS_PCAT_CODE: '||premium_pay_code||chr(10)||
                      'v_SUP_ID: '||v_SUP_ID||chr(10)||
                      --'SUP PIDM: '||trans_b_rec.POSN_SUPERVISOR_PIDM||' SUP POSN: '||v_SUP_POSN||' SUP SUFF: '||v_SUP_SUFF||
                      'v_originator_id: '||v_originator_id||chr(10)||
                      'PICT CODE: '||ptrecls_rec.PTRECLS_PICT_CODE||' PAY TYPE: '||v_PAY_TYPE||' Rate of Pay: '||trans_b_rec.POSN_RATE_OF_PAY||chr(10)||
                      'HRS PAY: '||hrs_pay||chr(10)||
                      'JCRE CODE: '||trans_b_rec.JOB_CHANGE_REASON_CODE||chr(10)||
                      'EPAF Transaction Number: '||epaf_transaction_no 
                      ||chr(10)
                      );  
               
                      
             --NOBTRAN record
            INSERT INTO POSNCTL.NOBTRAN (
               NOBTRAN_TRANSACTION_NO,
               NOBTRAN_PIDM,
               NOBTRAN_EFFECTIVE_DATE,
               NOBTRAN_ACAT_CODE,
               NOBTRAN_TRANS_STATUS_IND,
               NOBTRAN_SUBMITTOR_USER_ID,
               NOBTRAN_CREATED_DATE,
               NOBTRAN_ORIGINATOR_USER_ID,
               NOBTRAN_SUBMISSION_DATE,
               NOBTRAN_APPLY_IND,
               NOBTRAN_APPLY_DATE,
               NOBTRAN_APPLY_USER_ID,
               NOBTRAN_ACTIVITY_DATE,
               NOBTRAN_COMMENTS,
               NOBTRAN_SURROGATE_ID,
               NOBTRAN_VERSION,
               NOBTRAN_USER_ID,
               NOBTRAN_DATA_ORIGIN,
               NOBTRAN_VPDI_CODE)
            VALUES ( epaf_transaction_no,
             trans_b_rec.PASS_PIDM,
             v_eff_date,
             epaf_type,
             'A',  
             v_originator_id,
             sysdate,
             v_originator_id,   --hiring_mgr_oracle_id, 
             sysdate,
             'N',
             NULL,
             NULL,
             sysdate,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL );
             
             

               OPEN  nortran_field(epaf_type); 
               LOOP 
               FETCH nortran_field into nortran_rec ; 
                  EXIT WHEN nortran_field%notfound; 
                  dbms_output.put_line(nortran_rec.ntrapfd_aufd_code); 
                  field_value := NULL;
              --dbms_output.put_line('ntrapfd_aufd_code:  ' || rec.ntrapfd_aufd_code);
                  CASE nortran_rec.ntrapfd_aufd_code
                  WHEN 'PEBEMPL_BCAT_CODE' then
                      field_value := trans_b_rec.PASS_BCAT_CODE;

                  WHEN 'PEBEMPL_LCAT_CODE' then
                      field_value := trans_b_rec.PASS_LCAT_CODE;

                  WHEN 'PEBEMPL_ECLS_CODE' then
                      field_value := trans_b_rec.POSN_ECLS_CODE;
                
                  WHEN 'NBRJOBS_ECLS_CODE' then
                      field_value := trans_b_rec.POSN_ECLS_CODE;

                  WHEN 'PEBEMPL_EMPL_STATUS' then
                      field_value := 'A';

                  WHEN 'PEBEMPL_INTERNAL_FT_PT_IND' then
                      field_value := ptrecls_rec.PTRECLS_INTERNAL_FT_PT_IND;

                  WHEN 'NBRBJOB_CONTRACT_TYPE' then
                      field_value := trans_b_rec.POSN_CONTRACT_TYPE;
                 
                  WHEN 'NBRJOBS_ANN_SALARY' then
                        if (ptrecls_rec.PTRECLS_PICT_CODE = 'MN')  then
                            field_value :=    v_RATE_OF_PAY;
                        end if;

                    WHEN 'NBRJOBS_DESC' then
                      field_value := trans_b_rec.POSN_EXTENDED_TITLE;

                  WHEN 'NBRJOBS_EFFECTIVE_DATE' then
                   field_value := to_char(v_eff_date,'dd-MON-yyyy');

                  WHEN 'NBRJOBS_FTE' then
                      field_value := to_char(trans_b_rec.POSN_FTE);
                      
                  WHEN 'NBRBJOB_BEGIN_DATE' then
                      field_value := to_char(v_BEGIN_DATE,'dd-MON-yyyy');    

                  WHEN 'NBRJOBS_JCRE_CODE' then
                      field_value := trans_b_rec.JOB_CHANGE_REASON_CODE;


                  WHEN 'NBRJOBS_PCAT_CODE' then
                      field_value := premium_pay_code;

                  WHEN 'NBRJOBS_PERS_CHG_DATE' then
                     field_value := to_char(v_eff_date,'dd-MON-yyyy');

                  WHEN 'NBRJOBS_SAL_STEP' then
                      field_value := '0';

                  WHEN 'NBRJOBS_STATUS' then
                      field_value := 'A';

                  WHEN 'SUP_ID' then
                      field_value := v_SUP_ID;

                  WHEN 'NBRJOBS_HRS_PAY' then
                      field_value := to_char(hrs_pay);

                   
                  WHEN 'NBRJOBS_REG_RATE' then
                        if (ptrecls_rec.PTRECLS_PICT_CODE = 'SM')  then
                            field_value :=    v_RATE_OF_PAY;
                        end if;

                  WHEN 'NBRJOBS_TIME_ENTRY_METHOD' then
                      field_value := v_TIME_ENTRY_METHOD;
                      
                  WHEN 'NBRJOBS_COAS_CODE_TS' then
                  field_value := trans_b_rec.POSN_COAS_CODE;
                      
                  WHEN 'NBRJOBS_ORGN_CODE_TS' then
                  field_value := v_timesheet_org;
                  
                  WHEN 'NBRJOBS_FACTOR' then
                  field_value := to_char(factor);

                  WHEN 'NBRJOBS_HRS_DAY' then
                  field_value := to_char(hrs_day);

                  WHEN 'NBRJOBS_HRS_PAY' then
                  field_value := to_char(hrs_pay);

                  WHEN 'NBRJOBS_PAYS' then
                  field_value := to_char(pays);
                  
                   WHEN 'NBRJOBS_SGRP_CODE' then
                  field_value := v_NTRPCLS_SGRP_CODE;

                  WHEN 'NBRJOBS_SAL_GRADE' then
                  field_value := trans_b_rec.POSN_PAY_GRADE;    
                  
                  WHEN 'NBRJOBS_SAL_TABLE' then
                  field_value := v_NTRPCLS_Table;       


                  ELSE
                     dbms_output.put_line('Unknown field: '||nortran_rec.ntrapfd_aufd_code);
                  END CASE;


               INSERT INTO POSNCTL.NORTRAN (
                       NORTRAN_TRANSACTION_NO,
                       NORTRAN_APTY_CODE,
                       NORTRAN_POSN,
                       NORTRAN_SUFF,
                       NORTRAN_AUFM_CODE,
                       NORTRAN_AUBK_CODE,
                       NORTRAN_AUFD_CODE,
                       NORTRAN_VALUE,
                       NORTRAN_APPLY_STATUS_IND,
                       NORTRAN_ACTIVITY_DATE,
                       NORTRAN_DISPLAY_SEQ_NO,
                       NORTRAN_SURROGATE_ID,
                       NORTRAN_VERSION,
                       NORTRAN_USER_ID,
                       NORTRAN_DATA_ORIGIN,
                       NORTRAN_VPDI_CODE)
                    VALUES ( epaf_transaction_no,
                     nortran_rec.ntracat_apty_code,
                     trans_b_rec.POSN_NBR,
                     v_SUFF,
                     nortran_rec.ntrapfd_aufm_code,
                     nortran_rec.ntrapfd_aubk_code,
                     nortran_rec.ntrapfd_aufd_code,
                     field_value,
                     'P',
                     sysdate,
                     nortran_rec.NTRAPFD_DISPLAY_SEQ_NO,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL);



               END LOOP; 
               CLOSE nortran_field; 
               
               --NORTERN
            IF ( (SUBSTR(pass_trans_no,0,2)) <> 'SR' ) THEN    --HPSS-1701
                if (trans_b_rec.POSN_ECLS_CODE like 'E%' or trans_b_rec.POSN_ECLS_CODE like 'N%') and trans_b_rec.POSN_FTE = 1.0 then
                DBMS_OUTPUT.PUT_LINE(trans_b_rec.POSN_ECLS_CODE||' '||trans_b_rec.POSN_FTE ||'  Insert into nortern');
                   INSERT INTO POSNCTL.NORTERN (
                      NORTERN_TRANSACTION_NO,
                      NORTERN_APTY_CODE,
                      NORTERN_POSN,
                      NORTERN_SUFF,
                      NORTERN_EFFECTIVE_DATE,
                      NORTERN_EARN_CODE,
                      NORTERN_HRS,
                     NORTERN_SPECIAL_RATE,
                      NORTERN_SHIFT,
                      NORTERN_CANCEL_DATE,
                      NORTERN_ACTIVITY_DATE,
                      NORTERN_APPLY_STATUS_IND,
                      NORTERN_DEEMED_HRS,
                      NORTERN_SURROGATE_ID,
                      NORTERN_VERSION,
                      NORTERN_USER_ID,
                      NORTERN_DATA_ORIGIN,
                      NORTERN_VPDI_CODE)
                   VALUES ( epaf_transaction_no,
                            'EARN',
                            trans_b_rec.POSN_NBR,
                            v_SUFF,
                             v_eff_date,
                            'HLD',
                             1.0,
                             null,
                             1.0,
                             null,
                             sysdate,
                            'P', -- or 'A' ??
                             null,
                             null,
                             null,
                             null,
                             null,
                             null );
    
    
                else
                DBMS_OUTPUT.PUT_LINE(trans_b_rec.POSN_ECLS_CODE||' else Insert into nortern');
                     INSERT INTO POSNCTL.NORTERN (
                      NORTERN_TRANSACTION_NO,
                      NORTERN_APTY_CODE,
                      NORTERN_POSN,
                      NORTERN_SUFF,
                      NORTERN_EFFECTIVE_DATE,
                      NORTERN_EARN_CODE,
                      NORTERN_HRS,
                      NORTERN_SPECIAL_RATE,
                      NORTERN_SHIFT,
                      NORTERN_CANCEL_DATE,
                      NORTERN_ACTIVITY_DATE,
                      NORTERN_APPLY_STATUS_IND,
                      NORTERN_DEEMED_HRS,
                      NORTERN_SURROGATE_ID,
                      NORTERN_VERSION,
                      NORTERN_USER_ID,
                      NORTERN_DATA_ORIGIN,
                      NORTERN_VPDI_CODE)
                   VALUES ( epaf_transaction_no,
                            'EARN',
                             trans_b_rec.POSN_NBR,
                            v_SUFF,
                             v_eff_date,
                            'HLN',
                             1.0,
                             null,
                             1.0,
                             null,
                             sysdate,
                            'P', -- or 'A' ??
                             null,
                             null,
                             null,
                             null,
                             null,
                             null );
    
                end if;
    
                if trans_b_rec.POSN_ECLS_CODE like 'E%' or trans_b_rec.POSN_ECLS_CODE like 'F%' then
    
    
                DBMS_OUTPUT.PUT_LINE(trans_b_rec.POSN_ECLS_CODE||' Insert into nortern');
                     INSERT INTO POSNCTL.NORTERN (
                      NORTERN_TRANSACTION_NO,
                      NORTERN_APTY_CODE,
                      NORTERN_POSN,
                      NORTERN_SUFF,
                      NORTERN_EFFECTIVE_DATE,
                      NORTERN_EARN_CODE,
                      NORTERN_HRS,
                      NORTERN_SPECIAL_RATE,
                      NORTERN_SHIFT,
                      NORTERN_CANCEL_DATE,
                      NORTERN_ACTIVITY_DATE,
                      NORTERN_APPLY_STATUS_IND,
                      NORTERN_DEEMED_HRS,
                      NORTERN_SURROGATE_ID,
                      NORTERN_VERSION,
                      NORTERN_USER_ID,
                      NORTERN_DATA_ORIGIN,
                      NORTERN_VPDI_CODE)
                   VALUES ( epaf_transaction_no,
                            'EARN',
                             trans_b_rec.POSN_NBR,
                            v_SUFF,
                             v_eff_date,
                            'RGS',
                             hrs_pay,
                             null,
                             1.0,
                             null,
                             sysdate,
                            'P', -- or 'A' ??
                             null,
                             null,
                             null,
                             null,
                             null,
                             null );
    
                end if;
         END IF;  --HPSS-1701

               OPEN  transfunding_field(pass_trans_no); 
               LOOP 
               FETCH transfunding_field into transfunding_rec ; 
                  EXIT WHEN transfunding_field%notfound; 

              
                  
                  INSERT INTO POSNCTL.NORTLBD (
                   NORTLBD_TRANSACTION_NO,
                   NORTLBD_APTY_CODE,
                   NORTLBD_POSN,
                   NORTLBD_SUFF,
                   NORTLBD_EFFECTIVE_DATE,
                   NORTLBD_COAS_CODE,
                   NORTLBD_ACCI_CODE,
                   NORTLBD_FUND_CODE,
                   NORTLBD_ORGN_CODE,
                   NORTLBD_ACCT_CODE,
                   NORTLBD_PROG_CODE,
                   NORTLBD_ACTV_CODE,
                   NORTLBD_LOCN_CODE,
                   NORTLBD_PROJ_CODE,
                   NORTLBD_CTYP_CODE,
                   NORTLBD_ACCT_CODE_EXTERNAL,
                   NORTLBD_PERCENT,
                   NORTLBD_ACTIVITY_DATE,
                   NORTLBD_APPLY_STATUS_IND,
                   NORTLBD_ENC_OVERRIDE_END_DATE,
                   NORTLBD_SURROGATE_ID,
                   NORTLBD_VERSION,
                   NORTLBD_USER_ID,
                   NORTLBD_DATA_ORIGIN,
                   NORTLBD_VPDI_CODE)
                 VALUES ( epaf_transaction_no,
                          'LABOR',
                           trans_b_rec.POSN_NBR,
                          v_SUFF,
                           v_eff_date,  --confirmed_start_date,
                           trans_b_rec.POSN_COAS_CODE,
                           null,
                           transfunding_rec.PASS_POSN_FUND_CODE,
                           transfunding_rec.POSN_ORGN_CODE,
                           transfunding_rec.POSN_ACCT_CODE,
                           transfunding_rec.POSN_PROG_CODE,
                           null,
                           null,
                           null,
                           null,
                           null,
                           transfunding_rec.POSN_CURRENT_ACCT_PERCENT,
                           sysdate,
                          'P',  -- or 'A' ??
                           null,
                           null,
                           null,
                           null,
                           null,
                           null );   
               
               END LOOP; 
               CLOSE transfunding_field;    
                  

            OPEN norrout_field(epaf_type);

              LOOP
                   FETCH norrout_field INTO norrout_rec;
                   EXIT WHEN norrout_field%NOTFOUND;

                   DBMS_OUTPUT.PUT_LINE('NORROUT_TRANSACTION_NO: '|| epaf_transaction_no ||
                     'NORROUT_RECIPIENT_USER_ID: '|| norrout_rec.NTRLVID_USER_ID ||
                     'NORROUT_ACTION_USER_ID: NULL'||
                     'NORROUT_ALVL_CODE: '||  norrout_rec.ntraclv_alvl_code ||
                     
                     'NORROUT_ACTION_IND: '|| norrout_rec.ntraclv_action_ind||
                     'NORROUT_QUEUE_STATUS_IND: '|| 'P'||
                     'NORROUT_STATUS_DATE_TIME: '|| sysdate  ||
                     'NORROUT_ACTIVITY_DATE: '||  sysdate||
                     'NORROUT_LEVEL_NO: '||  norrout_rec.NTRALVL_LEVEL||
                     'NORROUT_SURROGATE_ID: NULL'||
                     'NORROUT_VERSION: NULL'||
                     'NORROUT_USER_ID: NULL'||
                     'NORROUT_DATA_ORIGIN: NULL'||
                     'NORROUT_VPDI_CODE: NULL');
                   INSERT INTO POSNCTL.NORROUT (
                     NORROUT_TRANSACTION_NO,
                     NORROUT_RECIPIENT_USER_ID,
                     NORROUT_ACTION_USER_ID,
                     NORROUT_ALVL_CODE,
                     NORROUT_ACTION_IND,
                     NORROUT_QUEUE_STATUS_IND,
                     NORROUT_STATUS_DATE_TIME,
                     NORROUT_ACTIVITY_DATE,
                     NORROUT_LEVEL_NO,
                     NORROUT_SURROGATE_ID,
                     NORROUT_VERSION,
                     NORROUT_USER_ID,
                     NORROUT_DATA_ORIGIN,
                     NORROUT_VPDI_CODE)
                  VALUES ( epaf_transaction_no,
                     norrout_rec.NTRLVID_USER_ID,
                     NULL,
                     norrout_rec.ntraclv_alvl_code ,
                     norrout_rec.ntraclv_action_ind ,
                     'P',
                     sysdate,
                     sysdate,
                     norrout_rec.NTRALVL_LEVEL,        -- norrout_rec.ntralvl_level,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL );
                     
              END LOOP;   
               CLOSE   norrout_field; 
               
               --Insert Comment
               select (max(NORCMNT_SEQ_NO) + 1 ) into v_norcmnt_sq from norcmnt;
               
               v_norcmnt_cmnt :=  'PASS '||pass_trans_no;
               
                INSERT INTO POSNCTL.NORCMNT (
                      NORCMNT_TRANSACTION_NO,	
                      NORCMNT_SEQ_NO,	
                      NORCMNT_COMMENTS,	
                      NORCMNT_ACTIVITY_DATE,	
                      NORCMNT_USER_ID	   
                      	)           
                  VALUES ( 
                      epaf_transaction_no,	
                      v_norcmnt_sq,
                      v_norcmnt_cmnt,
                      v_date,
                      'TT_HR_PASS'
                      	);
               

            sql_stmt := 'update TT_HR_PASS.NC_PASS_TRANS_B   SET   TRANS_STATUS = ''E'||''' , '|| 
                        ' EPAF_TRANSACTION_NO = '''|| epaf_transaction_no ||''' , '||
                        ' EPAF_CREATED_DATE =   '''|| v_date ||''''||
                        ' where TRANS_NO =  '''|| pass_trans_no ||'''';
                        
                         EXECUTE IMMEDIATE sql_stmt;
           rtn_flag := 'P';  
           DBMS_OUTPUT.PUT_LINE ('EPAF rtn_flag : '||rtn_flag);            

            DBMS_OUTPUT.PUT_LINE ('Query 2: '||sql_stmt);
              
            if utl_file.is_open (wfile_handle) then
              utl_file.fclose (wfile_handle);
              DBMS_OUTPUT.PUT_LINE ('File Closed : '||v_file);
            end if;


            select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
               into   v_eprint_user
                            from   dual;
               DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

                select gjbpseq.nextval
                   into v_one_up
                from DUAL;

                GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
                      ,'p_pass_banner_update'     -- e-Print Report definition (case sensitive)
                      ,'p_pass_banner_update.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
                      ,v_eprint_user            -- repository name
                      ,v_eprint_user);          -- user id (same as repository name)
                DBMS_OUTPUT.PUT_LINE('Sending eprint report');
                DBMS_OUTPUT.PUT_LINE (' Completed.');  
         ELSIF ((trans_b_rec.PASS_POSN_VACANT_BY_DATE IS NOT NULL) OR (trans_b_rec.PASS_PIDM IS NULL) )  THEN  --IF trans_b_rec.PASS_PIDM IS NOT NULL THEN  
            DBMS_OUTPUT.PUT_LINE('Vacant Position EPAF will not be created');
            sql_stmt := 'update TT_HR_PASS.NC_PASS_TRANS_B   SET   TRANS_STATUS = ''E'||''''||
                        ' where TRANS_NO =  '''|| pass_trans_no ||'''';
                        
                         EXECUTE IMMEDIATE sql_stmt;
           rtn_flag := 'P';  
           DBMS_OUTPUT.PUT_LINE ('EPAF rtn_flag : '||rtn_flag); 
          
         END IF;-- IF ( (trans_b_rec.PASS_PIDM IS NOT NULL) AND (v_new_exempt_ind = v_curr_exempt_ind)  AND (v_ep_flag = 'N') ) THEN
         
         DBMS_OUTPUT.PUT_LINE('v_curr_exempt_ind: '||v_curr_exempt_ind||' v_new_exempt_ind: '||v_new_exempt_ind||'PASS_VACANT_BY_DATE'||trans_b_rec.PASS_POSN_VACANT_BY_DATE||
         'PASS_PIDM'||trans_b_rec.PASS_PIDM||' v_nbrjobs_hrs_pay: '||v_nbrjobs_hrs_pay);
         
                IF ( (trans_b_rec.CURR_POSN_FTE <> trans_b_rec.POSN_FTE) AND (v_curr_exempt_ind = v_new_exempt_ind ) ) THEN  --END IF;  --IF (trans_b_rec.CURR_POSN_FTE <> trans_b_rec.POSN_FTE) THEN
				
				DBMS_OUTPUT.PUT_LINE('CURR_POSN_FTE: '||trans_b_rec.CURR_POSN_FTE||' POSN_FTE: '||trans_b_rec.POSN_FTE||
				' v_curr_exempt_ind: '||v_curr_exempt_ind||' v_new_exempt_ind: '||v_new_exempt_ind);
                
			
                  
                  /*IF(v_CURR_FT_PT_IND = 'P') THEN
                    v_ft_pt_ind_curr := 'P';
                  ELSIF( substr(v_CURR_ECLS_DESC,1,2) = 'FT' ) THEN
                    v_ft_pt_ind_curr := 'F' ;
                  END IF;
                  
                  IF(substr(v_NEW_ECLS_DESC,1,2) = 'PT') THEN
                    v_ft_pt_ind_new := 'P' ;
                  ELSIF( substr(v_NEW_ECLS_DESC,1,2) = 'FT' ) THEN
                    v_ft_pt_ind_new := 'F'  ;
                  END IF;*/
                  
                  v_JOBS_HRS_DAY := 8 * trans_b_rec.POSN_FTE;
                  IF(v_JOBS_HRS_DAY < 1) THEN
                      v_JOBS_HRS_DAY := 1;
                  END IF;
                                  
                  DBMS_OUTPUT.PUT_LINE('CURR_FTE: '||trans_b_rec.CURR_POSN_FTE||' POSN_FTE: '||trans_b_rec.POSN_FTE||chr(10)||
                  ' NEW ECLS DESC: '||v_NEW_ECLS_DESC||' OLD ECLS DESC: '||v_CURR_ECLS_DESC||chr(10)||
                  ' v_JOBS_HRS_PAY: '||v_JOBS_HRS_PAY||' v_JOBS_HRS_DAY: '||v_JOBS_HRS_DAY||chr(10)||
                  ' v_posn_sgrp_code,v_posn_table, v_posn_grade: '||v_posn_sgrp_code||v_posn_table||v_posn_grade
                  );
                  
                select NBRJOBS_ORGN_CODE_TS, NBRJOBS_SHIFT, NBRJOBS_FACTOR, NBRJOBS_PAYS, NBRJOBS_TIME_ENTRY_METHOD, 
                NBRJOBS_TIME_ENTRY_TYPE, NBRJOBS_TIME_IN_OUT_IND, NBRJOBS_LEAV_REPT_METHOD, NBRJOBS_PICT_CODE_LEAV_REPT ,
                NBRJOBS_HRS_DAY, NBRJOBS_ASSGN_SALARY ,NBRJOBS_PER_PAY_SALARY, NBRJOBS_PCAT_CODE , NBRJOBS_EMPR_CODE
                INTO jobs_rec  from
                NBRBJOB,NBRJOBS T1
                WHERE  
                NBRBJOB_PIDM = trans_b_rec.PASS_PIDM
                and NBRBJOB_POSN = trans_b_rec.POSN_NBR
                and nbrbjob_contract_type = 'P'  
                and ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
                   
                and t1.nbrjobs_pidm = nbrbjob_pidm
                AND T1.NBRJOBS_POSN = NBRBJOB_POSN
                and t1.nbrjobs_SUFF = NBRBJOB_SUFF
                AND T1.NBRJOBS_STATUS = 'A'          
                   
                   AND T1.NBRJOBS_EFFECTIVE_DATE =
                    (SELECT MAX(NBRJOBS_EFFECTIVE_DATE)
                    FROM NBRJOBS T11
                    WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                    AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                    AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                    AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE) ; 
           
                      IF (v_new_exempt_ind = 'Y') THEN
                      
                          v_JOBS_ASSGN_SALARY :=   trans_b_rec.POSN_RATE_OF_PAY / 12;
                          v_jobs_ann_sal      :=   trans_b_rec.POSN_RATE_OF_PAY ; 
                          v_JOBS_HRS_PAY      :=  173.33* trans_b_rec.POSN_FTE ;   

                      ELSIF (v_new_exempt_ind = 'N') THEN                          
                          
                         v_JOBS_ASSGN_SALARY :=   v_JOBS_HRS_PAY * trans_b_rec.POSN_RATE_OF_PAY;
                         v_jobs_ann_sal      :=  (v_JOBS_ASSGN_SALARY * jobs_rec.JOBS_FACTOR);
                         v_JOBS_HRS_PAY      :=  86.67* trans_b_rec.POSN_FTE ;     
                          
                      END IF; 
                      
                        /*IF ( (v_ft_pt_ind_new = 'F' ) AND (v_ft_pt_ind_curr = 'P') ) THEN 
                           v_NBRJOBS_PCAT_CODE := 'LONG';
                          --'HLD','Y'
                          --'HLN','N'-
                          v_NBREARN_EARN_CODE_NEW := 'HLD';
                          v_NBREARN_EARN_CODE_OLD := 'HLN';
                          
                        ELSIF ( (v_ft_pt_ind_new = 'P' ) AND (v_ft_pt_ind_curr = 'F') ) THEN                    
                          --'HLN','Y'
                          --'HLD','N'-
                          v_NBREARN_EARN_CODE_NEW := 'HLN';
                          v_NBREARN_EARN_CODE_OLD := 'HLD';
						  
                        ELSIF ( (v_ft_pt_ind_new = 'P' ) AND (v_ft_pt_ind_curr = 'P') ) THEN     
                          v_NBREARN_EARN_CODE_NEW := 'HLN';                        
						          END IF; */
                      
                      
                      
                      DBMS_OUTPUT.PUT_LINE(' v_ft_pt_ind_new: '||v_ft_pt_ind_new||chr(10)||
                      ' v_ft_pt_ind_curr: '||v_ft_pt_ind_curr||chr(10)||
                      ' v_NBRJOBS_PCAT_CODE: '||v_NBRJOBS_PCAT_CODE
                      );
                      
                      IF(trans_b_rec.POSN_COAS_CODE <> 'E') THEN
                        v_NBRJOBS_EMPR_CODE := 'TT';
                      ELSE
                        v_NBRJOBS_EMPR_CODE := NULL;  
                      END IF;
					  
					  DBMS_OUTPUT.PUT_LINE('v_NBREARN_EARN_CODE_NEW: '||v_NBREARN_EARN_CODE_NEW||' v_NBREARN_EARN_CODE_OLD: '||v_NBREARN_EARN_CODE_OLD||
				    ' v_ft_pt_ind_new: '||v_ft_pt_ind_new||' v_ft_pt_ind_curr: '||v_ft_pt_ind_curr||' v_NBRJOBS_PCAT_CODE: '||v_NBRJOBS_PCAT_CODE);
                      
                      Insert into NBRJOBS
                           (NBRJOBS_PIDM, NBRJOBS_POSN, NBRJOBS_SUFF, NBRJOBS_EFFECTIVE_DATE,
                           
                            NBRJOBS_STATUS, NBRJOBS_ECLS_CODE, NBRJOBS_PICT_CODE, NBRJOBS_ORGN_CODE_TS, 
                           
                            NBRJOBS_APPT_PCT, NBRJOBS_HRS_DAY, NBRJOBS_HRS_PAY, NBRJOBS_SHIFT,
                           
                            NBRJOBS_ASSGN_SALARY, NBRJOBS_FACTOR, NBRJOBS_ANN_SALARY, NBRJOBS_PER_PAY_SALARY,
                           
                            NBRJOBS_PAYS, NBRJOBS_PER_PAY_DEFER_AMT, NBRJOBS_SAL_TABLE, NBRJOBS_SAL_GRADE,  
                            
                            NBRJOBS_PERS_CHG_DATE, NBRJOBS_TIME_ENTRY_METHOD, NBRJOBS_TIME_ENTRY_TYPE, NBRJOBS_TIME_IN_OUT_IND,
                            
                            NBRJOBS_LEAV_REPT_METHOD, NBRJOBS_PICT_CODE_LEAV_REPT,  NBRJOBS_FTE, NBRJOBS_DESC, 
                            
                            NBRJOBS_SGRP_CODE, NBRJOBS_JCRE_CODE, NBRJOBS_PCAT_CODE, NBRJOBS_USER_ID, NBRJOBS_ACTIVITY_DATE, 
                            
                            NBRJOBS_REG_RATE, NBRJOBS_SAL_STEP, NBRJOBS_COAS_CODE_TS, NBRJOBS_EMPR_CODE,
                            
                            NBRJOBS_SUPERVISOR_PIDM, NBRJOBS_SUPERVISOR_POSN, NBRJOBS_SUPERVISOR_SUFF  )
                           Values
                           (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF   , trans_b_rec.POSN_EFFECTIVE_DATE,
                           
                            'A', trans_b_rec.POSN_ECLS_CODE, trans_b_rec.POSN_PICT_CODE, jobs_rec.JOBS_ORGN_CODE_TS, 
                           
                            100, v_JOBS_HRS_DAY, v_JOBS_HRS_PAY, 1 ,
                           
                            v_JOBS_ASSGN_SALARY, jobs_rec.JOBS_FACTOR, v_jobs_ann_sal, v_JOBS_ASSGN_SALARY,
                           
                            jobs_rec.JOBS_PAYS, 0, v_posn_table, v_posn_grade,  
                            
                            trans_b_rec.POSN_EFFECTIVE_DATE, jobs_rec.JOBS_TIME_ENTRY_METHOD, jobs_rec.JOBS_TIME_ENTRY_TYPE, jobs_rec.JOBS_TIME_IN_OUT_IND,
                            
                            jobs_rec.JOBS_LEAV_REPT_METHOD, jobs_rec.JOBS_PICT_CODE_LEAV_REPT,  trans_b_rec.POSN_FTE,  trans_b_rec.POSN_EXTENDED_TITLE, 
                            
                            v_posn_sgrp_code, trans_b_rec.JOB_CHANGE_REASON_CODE, v_NBRJOBS_PCAT_CODE, 'TT_HR_PASS', sysdate, 
                            
                            trans_b_rec.POSN_RATE_OF_PAY, 0, trans_b_rec.POSN_COAS_CODE, v_NBRJOBS_EMPR_CODE,
                            
                            trans_b_rec.POSN_SUPERVISOR_PIDM,v_SUP_POSN  , v_SUP_SUFF);
                            
                            INSERT INTO NBREARN ( NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF, NBREARN_EFFECTIVE_DATE,NBREARN_HRS,
                            NBREARN_EARN_CODE, NBREARN_ACTIVE_IND, NBREARN_SHIFT, NBREARN_ACTIVITY_DATE, NBREARN_USER_ID)
                            Values
                            (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,1, 
                             v_NBREARN_EARN_CODE_NEW,'Y',1,sysdate , 'TT_HR_PASS');
							
            							IF ( v_ft_pt_ind_new <> v_ft_pt_ind_curr  ) THEN 
            
            							DBMS_OUTPUT.PUT_LINE('v_ft_pt_ind_new <> v_ft_pt_ind_curr: ');
                                  
                                        INSERT INTO NBREARN ( NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF, NBREARN_EFFECTIVE_DATE,NBREARN_HRS,
                                        NBREARN_EARN_CODE, NBREARN_ACTIVE_IND, NBREARN_SHIFT, NBREARN_ACTIVITY_DATE, NBREARN_USER_ID)
                                        Values
                                        (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,1, 
                                         v_NBREARN_EARN_CODE_OLD,'N',1,sysdate , 'TT_HR_PASS');
                                  
            							END IF;
							
                        FOR fund_loop IN ( select POSN_FUND_CODE,POSN_ORGN_CODE,POSN_ACCT_CODE, POSN_PROPOSED_ACCT_PERCENT , POSN_PROG_CODE
                        from tt_hr_pass.nc_pass_transfunding_r where NC_PASS_TRANS_B_ID = trans_b_rec.TRANS_ID                    
                        )
                        LOOP
                            INSERT INTO NBRJLBD (
                            NBRJLBD_PIDM, NBRJLBD_POSN, NBRJLBD_SUFF, NBRJLBD_EFFECTIVE_DATE, 
                            NBRJLBD_PERCENT, NBRJLBD_SALARY_ENC_TO_POST, NBRJLBD_FRINGE_ENC_TO_POST, NBRJLBD_CHANGE_IND, 
                            NBRJLBD_ACTIVITY_DATE,  NBRJLBD_FUND_CODE, 
                            NBRJLBD_ORGN_CODE, NBRJLBD_ACCT_CODE, NBRJLBD_PROG_CODE, NBRJLBD_USER_ID
                            )
                            VALUES(
                            trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,
                            fund_loop.POSN_PROPOSED_ACCT_PERCENT,0,0,'A',
                            sysdate,fund_loop.POSN_FUND_CODE,
                            fund_loop.POSN_ORGN_CODE,fund_loop.POSN_ACCT_CODE,fund_loop.POSN_PROG_CODE,'TT_HR_PASS');  
                        END LOOP;
                        
                        sql_stmt := 'update TT_HR_PASS.NC_PASS_TRANS_B   SET   TRANS_STATUS = ''E'||''' , '||
                        ' EPAF_CREATED_DATE =   '''|| v_date ||''''||
                        ' where TRANS_NO =  '''|| pass_trans_no ||'''';

                        EXECUTE IMMEDIATE sql_stmt; 

                END IF;  --IF (trans_b_rec.CURR_POSN_FTE <> trans_b_rec.POSN_FTE) THEN
         
                IF ( ((v_new_exempt_ind = 'N') AND (v_curr_exempt_ind = 'Y')) AND ((trans_b_rec.PASS_POSN_VACANT_BY_DATE IS NOT NULL) OR (trans_b_rec.PASS_PIDM IS NOT NULL) ) ) THEN
                --END IF;    --IF ( ((v_new_exempt_ind = 'N') AND (v_curr_exempt_ind = 'Y')) AND ((trans_b_rec.PASS_POSN_VACANT_BY_DATE IS NOT NULL) OR (trans_b_rec.PASS_PIDM IS NOT NULL) ) ) THEN
                v_nbrjobs_hrs_pay := 86.67 * trans_b_rec.POSN_FTE ;
                v_NBRJOBS_REG_RATE :=  trans_b_rec.POSN_RATE_OF_PAY;

                  
                DBMS_OUTPUT.PUT_LINE( 'v_nbrjobs_hrs_pay: '||v_nbrjobs_hrs_pay||' PASS_POSN_VACANT_BY_DATE: '||trans_b_rec.PASS_POSN_VACANT_BY_DATE||
                ' PASS_PIDM: '||trans_b_rec.PASS_PIDM );
                
                SELECT COUNT(*) 
                INTO v_TCP_ORG_COUNT 
                FROM TTUFISCAL.PWRTCPC 
                where PWRTCPC_COAS_CODE = trans_b_rec.POSN_COAS_CODE
                and PWRTCPC_ORGN_CODE_TS like trans_b_rec.POSN_ORGN_CODE;
                
                     if v_TCP_ORG_COUNT > 0 then
                     v_TIME_ENTRY_METHOD := 'T';
                     else
                     v_TIME_ENTRY_METHOD := 'W';
                     end if; 
					 
				select NBRJOBS_ORGN_CODE_TS, NBRJOBS_SHIFT, NBRJOBS_FACTOR, NBRJOBS_PAYS, NBRJOBS_TIME_ENTRY_METHOD, 
                NBRJOBS_TIME_ENTRY_TYPE, NBRJOBS_TIME_IN_OUT_IND, NBRJOBS_LEAV_REPT_METHOD, NBRJOBS_PICT_CODE_LEAV_REPT ,
                NBRJOBS_HRS_DAY, NBRJOBS_ASSGN_SALARY ,NBRJOBS_PER_PAY_SALARY, NBRJOBS_PCAT_CODE , NBRJOBS_EMPR_CODE
                INTO jobs_rec  from
                NBRBJOB,NBRJOBS T1
                WHERE  
                NBRBJOB_PIDM = trans_b_rec.PASS_PIDM
                and NBRBJOB_POSN = trans_b_rec.POSN_NBR
                and nbrbjob_contract_type = 'P'  
                and ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
                   
                and t1.nbrjobs_pidm = nbrbjob_pidm
                AND T1.NBRJOBS_POSN = NBRBJOB_POSN
                and t1.nbrjobs_SUFF = NBRBJOB_SUFF
                AND T1.NBRJOBS_STATUS = 'A'          
                   
                   AND T1.NBRJOBS_EFFECTIVE_DATE =
                    (SELECT MAX(NBRJOBS_EFFECTIVE_DATE)
                    FROM NBRJOBS T11
                    WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                    AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                    AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                    AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE) ; 	
        --HPSS-1679            
        v_JOBS_ASSGN_SALARY :=   v_JOBS_HRS_PAY * trans_b_rec.POSN_RATE_OF_PAY;
        v_jobs_ann_sal      :=  (v_JOBS_ASSGN_SALARY * 24);     
                                                                      
        DBMS_OUTPUT.PUT_LINE( 'v_JOBS_ASSGN_SALARY: '||v_JOBS_ASSGN_SALARY||' v_jobs_ann_sal: '||v_jobs_ann_sal||' v_JOBS_HRS_PAY: '||v_JOBS_HRS_PAY||
                ' trans_b_rec.POSN_RATE_OF_PAY: '||trans_b_rec.POSN_RATE_OF_PAY||' jobs_rec.JOBS_FACTOR: '||jobs_rec.JOBS_FACTOR||
                ' v_NBREARN_EARN_CODE_NEW: '||v_NBREARN_EARN_CODE_NEW||' v_NBREARN_EARN_CODE_OLD: '||v_NBREARN_EARN_CODE_OLD||
				        ' v_ft_pt_ind_new: '||v_ft_pt_ind_new||' v_ft_pt_ind_curr: '||v_ft_pt_ind_curr||' v_NBRJOBS_PCAT_CODE: '||v_NBRJOBS_PCAT_CODE
                 );
                
				
				Insert into NBRJOBS
			   (NBRJOBS_PIDM, NBRJOBS_POSN, NBRJOBS_SUFF, NBRJOBS_EFFECTIVE_DATE,
			   
				NBRJOBS_STATUS, NBRJOBS_ECLS_CODE, NBRJOBS_PICT_CODE, NBRJOBS_ORGN_CODE_TS, 
			   
				NBRJOBS_APPT_PCT, NBRJOBS_HRS_DAY, NBRJOBS_HRS_PAY, NBRJOBS_SHIFT,
			   
				NBRJOBS_ASSGN_SALARY, NBRJOBS_FACTOR, NBRJOBS_ANN_SALARY, NBRJOBS_PER_PAY_SALARY,
			   
				NBRJOBS_PAYS, NBRJOBS_PER_PAY_DEFER_AMT, NBRJOBS_SAL_TABLE, NBRJOBS_SAL_GRADE,  
				
				NBRJOBS_PERS_CHG_DATE, NBRJOBS_TIME_ENTRY_METHOD, NBRJOBS_TIME_ENTRY_TYPE, NBRJOBS_TIME_IN_OUT_IND,
				
				NBRJOBS_LEAV_REPT_METHOD, NBRJOBS_PICT_CODE_LEAV_REPT,  NBRJOBS_FTE, NBRJOBS_DESC, 
				
				NBRJOBS_SGRP_CODE, NBRJOBS_JCRE_CODE, NBRJOBS_PCAT_CODE, NBRJOBS_USER_ID, NBRJOBS_ACTIVITY_DATE, 
				
				NBRJOBS_REG_RATE, NBRJOBS_SAL_STEP, NBRJOBS_COAS_CODE_TS, NBRJOBS_EMPR_CODE,
				
				NBRJOBS_SUPERVISOR_PIDM, NBRJOBS_SUPERVISOR_POSN, NBRJOBS_SUPERVISOR_SUFF  )
			   Values
			   (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF   , trans_b_rec.POSN_EFFECTIVE_DATE,
			   
				'A', trans_b_rec.POSN_ECLS_CODE, trans_b_rec.POSN_PICT_CODE, jobs_rec.JOBS_ORGN_CODE_TS, 
			   
				100, jobs_rec.JOBS_HRS_DAY, v_nbrjobs_hrs_pay, 1 ,
			   
				v_JOBS_ASSGN_SALARY, 24, v_jobs_ann_sal, jobs_rec.JOBS_ASSGN_SALARY,
			   
				24, 0, v_posn_table, v_posn_grade,  
				
				trans_b_rec.POSN_EFFECTIVE_DATE, v_TIME_ENTRY_METHOD, 'T', jobs_rec.JOBS_TIME_IN_OUT_IND,
				
				'W', 'SM',  trans_b_rec.POSN_FTE,  trans_b_rec.POSN_EXTENDED_TITLE, 
				
				v_posn_sgrp_code, trans_b_rec.JOB_CHANGE_REASON_CODE, v_NBRJOBS_PCAT_CODE, 'TT_HR_PASS', sysdate, 
				
				v_NBRJOBS_REG_RATE, 0, trans_b_rec.POSN_COAS_CODE, jobs_rec.JOBS_EMPR_CODE,
				
				trans_b_rec.POSN_SUPERVISOR_PIDM,v_SUP_POSN  , v_SUP_SUFF); 	
                
                --insert into history table
                insert into PERJHIS(
                PERJHIS_PIDM, PERJHIS_USER_ID, PERJHIS_ACTIVITY_DATE, PERJHIS_POSN,
                PERJHIS_EFFECTIVE_DATE, --NBRJOBS_EFFECTIVE_DATE 
                PERJHIS_PERS_CHG_DATE, --NBRJOBS_PERS_CHG_DATE 
                PERJHIS_DESC, --NBRJOBS_DESC  
                PERJHIS_ECLS_CODE, --NBRJOBS_ECLS_CODE
                PERJHIS_JCRE_CODE, --NBRJOBS_JCRE_CODE
                PERJHIS_SGRP_CODE, --NBRJOBS_SGRP_CODE
                PERJHIS_SAL_TABLE, --NBRJOBS_SAL_TABLE
                PERJHIS_SAL_GRADE, --NBRJOBS_SAL_GRADE
                PERJHIS_ANN_SALARY, --nbrjobs_ann_salary
                PERJHIS_HRS_PAY,--nbrjobs_hrs_pay
                PERJHIS_FTE                
                )
                select NBRJOBS_PIDM,  'TT_HR_PASS', sysdate, nbrjobs_posn, 
                NBRJOBS_EFFECTIVE_DATE ,
                NBRJOBS_PERS_CHG_DATE ,
                NBRJOBS_DESC  ,
                NBRJOBS_ECLS_CODE,
                NBRJOBS_JCRE_CODE,
                NBRJOBS_SGRP_CODE,
                NBRJOBS_SAL_TABLE,
                NBRJOBS_SAL_GRADE,
                nbrjobs_ann_salary,
                nbrjobs_hrs_pay,
                NBRJOBS_FTE
                from nbrjobs
                where  nbrjobs_posn = trans_b_rec.POSN_NBR and NBRJOBS_EFFECTIVE_DATE = 
                (select max(NBRJOBS_EFFECTIVE_DATE) from nbrjobs where nbrjobs_posn = trans_b_rec.POSN_NBR
                 and nbrjobs_status = 'A')
                ;
                

                
                 /*sql_stmt := '  update nbrearn a  '||
                 ' set NBREARN_EFFECTIVE_DATE = '''||trans_b_rec.CALC_EFF_DATE||''''||
                 '   where a.NBREARN_POSN = '''||trans_b_rec.POSN_NBR||''''||
                 '  and a.NBREARN_PIDM = '''||trans_b_rec.PASS_PIDM ||''''||
                 '  and a.NBREARN_EARN_CODE = ''HLD'''||
                 '  and a.NBREARN_EFFECTIVE_DATE = ( '||
                 '  select max(NBREARN_EFFECTIVE_DATE) from nbrearn  b '|| 
                 '  where b.NBREARN_POSN =  a.NBREARN_POSN '||
                 '  and a.NBREARN_PIDM = b.NBREARN_PIDM '||
                 '  and a.NBREARN_EARN_CODE = b.NBREARN_EARN_CODE '||
                 '  ) '; 
                   
                dbms_output.put_line(' update nbrearn sql_stmt: '||sql_stmt);
                
                EXECUTE IMMEDIATE sql_stmt; */
                --HPSS-1679
                INSERT INTO NBREARN ( NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF, NBREARN_EFFECTIVE_DATE,NBREARN_HRS,
                NBREARN_EARN_CODE, NBREARN_ACTIVE_IND, NBREARN_SHIFT, NBREARN_ACTIVITY_DATE, NBREARN_USER_ID)
                Values
                (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,1, 
                v_NBREARN_EARN_CODE_NEW,'Y',1,sysdate , 'TT_HR_PASS');
                							
                IF ( v_ft_pt_ind_new <> v_ft_pt_ind_curr  ) THEN 
                
                DBMS_OUTPUT.PUT_LINE('v_ft_pt_ind_new <> v_ft_pt_ind_curr: ');
                                      
                INSERT INTO NBREARN ( NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF, NBREARN_EFFECTIVE_DATE,NBREARN_HRS,
                NBREARN_EARN_CODE, NBREARN_ACTIVE_IND, NBREARN_SHIFT, NBREARN_ACTIVITY_DATE, NBREARN_USER_ID)
                Values
                (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,1, 
                v_NBREARN_EARN_CODE_OLD,'N',1,sysdate , 'TT_HR_PASS');
                                      
                END IF;				
                

                insert into nbrearn 
                (NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF ,
                 NBREARN_EFFECTIVE_DATE , NBREARN_EARN_CODE , NBREARN_ACTIVE_IND , 
                 NBREARN_SHIFT , NBREARN_ACTIVITY_DATE , NBREARN_USER_ID 
                )
                values
                (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF,
                 trans_b_rec.CALC_EFF_DATE, 'RGS','N',
                 1, sysdate,'TT_HR_PASS'                
                );
                
              FOR fund_loop IN ( select POSN_FUND_CODE,POSN_ORGN_CODE,POSN_ACCT_CODE, POSN_PROPOSED_ACCT_PERCENT , POSN_PROG_CODE
                        from tt_hr_pass.nc_pass_transfunding_r where NC_PASS_TRANS_B_ID = trans_b_rec.TRANS_ID                    
                        )
                LOOP
                  INSERT INTO NBRJLBD (
                  NBRJLBD_PIDM, NBRJLBD_POSN, NBRJLBD_SUFF, NBRJLBD_EFFECTIVE_DATE, 
                  NBRJLBD_PERCENT, NBRJLBD_SALARY_ENC_TO_POST, NBRJLBD_FRINGE_ENC_TO_POST, NBRJLBD_CHANGE_IND, 
                  NBRJLBD_ACTIVITY_DATE,  NBRJLBD_FUND_CODE, 
                  NBRJLBD_ORGN_CODE, NBRJLBD_ACCT_CODE, NBRJLBD_PROG_CODE, NBRJLBD_USER_ID
                  )
                  VALUES(
                  trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,
                  fund_loop.POSN_PROPOSED_ACCT_PERCENT,0,0,'A',
                  sysdate,fund_loop.POSN_FUND_CODE,
                  fund_loop.POSN_ORGN_CODE,fund_loop.POSN_ACCT_CODE,fund_loop.POSN_PROG_CODE,'TT_HR_PASS');  
               END LOOP;  
               
              sql_stmt := 'update TT_HR_PASS.NC_PASS_TRANS_B   SET   TRANS_STATUS = ''E'||''' , '||
              ' EPAF_CREATED_DATE =   '''|| v_date ||''''||
              ' where TRANS_NO =  '''|| pass_trans_no ||'''';

              EXECUTE IMMEDIATE sql_stmt; 
               
              
       ELSIF ( ((v_new_exempt_ind = 'Y') AND (v_curr_exempt_ind = 'N')) AND ((trans_b_rec.PASS_POSN_VACANT_BY_DATE IS NOT NULL) OR (trans_b_rec.PASS_PIDM IS NOT NULL)) ) THEN  
       --IF ( ((v_new_exempt_ind = 'N') AND (v_curr_exempt_ind = 'Y')) AND ((trans_b_rec.PASS_POSN_VACANT_BY_DATE IS NOT NULL) OR (trans_b_rec.PASS_PIDM IS NOT NULL) ) ) THEN
               
                v_nbrjobs_hrs_pay := 173.33 * trans_b_rec.POSN_FTE ;
                v_NBRJOBS_REG_RATE := trans_b_rec.POSN_RATE_OF_PAY / (173.33 * 12);
                DBMS_OUTPUT.PUT_LINE('Moving to Exempt v_new_exempt_ind: ' ||v_new_exempt_ind||chr(9)||' v_curr_exempt_ind: '||chr(9)||v_curr_exempt_ind||chr(9)||
                ' v_nbrjobs_hrs_pay: '||v_nbrjobs_hrs_pay||' v_NBRJOBS_REG_RATE: '||v_NBRJOBS_REG_RATE);
				
				select NBRJOBS_ORGN_CODE_TS, NBRJOBS_SHIFT, NBRJOBS_FACTOR, NBRJOBS_PAYS, NBRJOBS_TIME_ENTRY_METHOD, 
                NBRJOBS_TIME_ENTRY_TYPE, NBRJOBS_TIME_IN_OUT_IND, NBRJOBS_LEAV_REPT_METHOD, NBRJOBS_PICT_CODE_LEAV_REPT ,
                NBRJOBS_HRS_DAY, NBRJOBS_ASSGN_SALARY ,NBRJOBS_PER_PAY_SALARY, NBRJOBS_PCAT_CODE , NBRJOBS_EMPR_CODE
                INTO jobs_rec  from
                NBRBJOB,NBRJOBS T1
                WHERE  
                NBRBJOB_PIDM = trans_b_rec.PASS_PIDM
                and NBRBJOB_POSN = trans_b_rec.POSN_NBR
                and nbrbjob_contract_type = 'P'  
                and ((NBRBJOB_BEGIN_DATE < SYSDATE) AND (NBRBJOB_END_DATE IS NULL OR NBRBJOB_END_DATE > SYSDATE))
                   
                and t1.nbrjobs_pidm = nbrbjob_pidm
                AND T1.NBRJOBS_POSN = NBRBJOB_POSN
                and t1.nbrjobs_SUFF = NBRBJOB_SUFF
                AND T1.NBRJOBS_STATUS = 'A'          
                   
                   AND T1.NBRJOBS_EFFECTIVE_DATE =
                    (SELECT MAX(NBRJOBS_EFFECTIVE_DATE)
                    FROM NBRJOBS T11
                    WHERE     T11.NBRJOBS_PIDM = T1.NBRJOBS_PIDM
                    AND T11.NBRJOBS_POSN = T1.NBRJOBS_POSN
                    AND T11.NBRJOBS_SUFF = T1.NBRJOBS_SUFF
                    AND T11.NBRJOBS_EFFECTIVE_DATE <= SYSDATE) ; 	
        --HPSS-1679            
        v_JOBS_ASSGN_SALARY :=   trans_b_rec.POSN_RATE_OF_PAY / 12;
        v_jobs_ann_sal      :=   trans_b_rec.POSN_RATE_OF_PAY ; 
        
        DBMS_OUTPUT.PUT_LINE('v_JOBS_ASSGN_SALARY: ' ||v_JOBS_ASSGN_SALARY||' v_jobs_ann_sal: '||v_jobs_ann_sal||
        ' trans_b_rec.POSN_RATE_OF_PAY: '||trans_b_rec.POSN_RATE_OF_PAY ||
        'v_NBREARN_EARN_CODE_NEW: '||v_NBREARN_EARN_CODE_NEW||' v_NBREARN_EARN_CODE_OLD: '||v_NBREARN_EARN_CODE_OLD||
				    ' v_ft_pt_ind_new: '||v_ft_pt_ind_new||' v_ft_pt_ind_curr: '||v_ft_pt_ind_curr||' v_NBRJOBS_PCAT_CODE: '||v_NBRJOBS_PCAT_CODE); 
        
                       
					
				Insert into NBRJOBS
			   (NBRJOBS_PIDM, NBRJOBS_POSN, NBRJOBS_SUFF, NBRJOBS_EFFECTIVE_DATE,
			   
				NBRJOBS_STATUS, NBRJOBS_ECLS_CODE, NBRJOBS_PICT_CODE, NBRJOBS_ORGN_CODE_TS, 
			   
				NBRJOBS_APPT_PCT, NBRJOBS_HRS_DAY, NBRJOBS_HRS_PAY, NBRJOBS_SHIFT,
			   
				NBRJOBS_ASSGN_SALARY, NBRJOBS_FACTOR, NBRJOBS_ANN_SALARY, NBRJOBS_PER_PAY_SALARY,
			   
				NBRJOBS_PAYS, NBRJOBS_PER_PAY_DEFER_AMT, NBRJOBS_SAL_TABLE, NBRJOBS_SAL_GRADE,  
				
				NBRJOBS_PERS_CHG_DATE, NBRJOBS_TIME_ENTRY_METHOD, NBRJOBS_TIME_ENTRY_TYPE, NBRJOBS_TIME_IN_OUT_IND,
				
				NBRJOBS_LEAV_REPT_METHOD, NBRJOBS_PICT_CODE_LEAV_REPT,  NBRJOBS_FTE, NBRJOBS_DESC, 
				
				NBRJOBS_SGRP_CODE, NBRJOBS_JCRE_CODE, NBRJOBS_PCAT_CODE, NBRJOBS_USER_ID, NBRJOBS_ACTIVITY_DATE, 
				
				NBRJOBS_REG_RATE, NBRJOBS_SAL_STEP, NBRJOBS_COAS_CODE_TS, NBRJOBS_EMPR_CODE,
				
				NBRJOBS_SUPERVISOR_PIDM, NBRJOBS_SUPERVISOR_POSN, NBRJOBS_SUPERVISOR_SUFF  )
			   Values
			   (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF   , trans_b_rec.POSN_EFFECTIVE_DATE,
			   
				'A', trans_b_rec.POSN_ECLS_CODE, trans_b_rec.POSN_PICT_CODE, jobs_rec.JOBS_ORGN_CODE_TS, 
			   
				100, jobs_rec.JOBS_HRS_DAY, v_nbrjobs_hrs_pay, 1 ,
			   
				v_JOBS_ASSGN_SALARY, 12, v_jobs_ann_sal, jobs_rec.JOBS_ASSGN_SALARY,
			   
				12, 0, v_posn_table, v_posn_grade,  
				
				trans_b_rec.POSN_EFFECTIVE_DATE, 'P', 'E', jobs_rec.JOBS_TIME_IN_OUT_IND,
				
				'W', 'MN',  trans_b_rec.POSN_FTE,  trans_b_rec.POSN_EXTENDED_TITLE, 
				
				v_posn_sgrp_code, trans_b_rec.JOB_CHANGE_REASON_CODE, v_NBRJOBS_PCAT_CODE, 'TT_HR_PASS', sysdate, 
				
				v_NBRJOBS_REG_RATE, 0, trans_b_rec.POSN_COAS_CODE, jobs_rec.JOBS_EMPR_CODE,
				
				trans_b_rec.POSN_SUPERVISOR_PIDM,v_SUP_POSN  , v_SUP_SUFF); 
                
                --insert into history table
                insert into PERJHIS(
                PERJHIS_PIDM, PERJHIS_USER_ID, PERJHIS_ACTIVITY_DATE, PERJHIS_POSN,
                PERJHIS_EFFECTIVE_DATE, --NBRJOBS_EFFECTIVE_DATE 
                PERJHIS_PERS_CHG_DATE, --NBRJOBS_PERS_CHG_DATE 
                PERJHIS_DESC, --NBRJOBS_DESC  
                PERJHIS_ECLS_CODE, --NBRJOBS_ECLS_CODE
                PERJHIS_JCRE_CODE, --NBRJOBS_JCRE_CODE
                PERJHIS_SGRP_CODE, --NBRJOBS_SGRP_CODE
                PERJHIS_SAL_TABLE, --NBRJOBS_SAL_TABLE
                PERJHIS_SAL_GRADE, --NBRJOBS_SAL_GRADE
                PERJHIS_ANN_SALARY, --nbrjobs_ann_salary
                PERJHIS_HRS_PAY, --nbrjobs_hrs_pay
                PERJHIS_FTE                
                )
                select NBRJOBS_PIDM,  'TT_HR_PASS', sysdate, nbrjobs_posn, 
                NBRJOBS_EFFECTIVE_DATE ,
                NBRJOBS_PERS_CHG_DATE ,
                NBRJOBS_DESC  ,
                NBRJOBS_ECLS_CODE,
                NBRJOBS_JCRE_CODE,
                NBRJOBS_SGRP_CODE,
                NBRJOBS_SAL_TABLE,
                NBRJOBS_SAL_GRADE,
                nbrjobs_ann_salary,
                nbrjobs_hrs_pay,
                nbrjobs_fte 
                from nbrjobs
                where  nbrjobs_posn = trans_b_rec.POSN_NBR and NBRJOBS_EFFECTIVE_DATE = 
                (select max(NBRJOBS_EFFECTIVE_DATE) from nbrjobs where nbrjobs_posn = trans_b_rec.POSN_NBR
                 and nbrjobs_status = 'A') ;
                 
                insert into nbrearn(
                NBREARN_PIDM,         NBREARN_POSN,          NBREARN_SUFF, 
                NBREARN_EFFECTIVE_DATE,         NBREARN_EARN_CODE,  NBREARN_ACTIVE_IND,    
                NBREARN_SHIFT,    NBREARN_ACTIVITY_DATE, NBREARN_HRS, NBREARN_USER_ID
                )
                values(
                trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF,
                trans_b_rec.CALC_EFF_DATE, 'RGS', 'Y',
                1,sysdate, v_nbrjobs_hrs_pay, 'TT_HR_PASS'
                ) ;
                --HPSS-1679
                INSERT INTO NBREARN ( NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF, NBREARN_EFFECTIVE_DATE,NBREARN_HRS,
                NBREARN_EARN_CODE, NBREARN_ACTIVE_IND, NBREARN_SHIFT, NBREARN_ACTIVITY_DATE, NBREARN_USER_ID)
                Values
                (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,1, 
                v_NBREARN_EARN_CODE_NEW,'Y',1,sysdate , 'TT_HR_PASS');
                							
                IF ( v_ft_pt_ind_new <> v_ft_pt_ind_curr  ) THEN 
                
                DBMS_OUTPUT.PUT_LINE('v_ft_pt_ind_new <> v_ft_pt_ind_curr: ');
                                      
                INSERT INTO NBREARN ( NBREARN_PIDM, NBREARN_POSN, NBREARN_SUFF, NBREARN_EFFECTIVE_DATE,NBREARN_HRS,
                NBREARN_EARN_CODE, NBREARN_ACTIVE_IND, NBREARN_SHIFT, NBREARN_ACTIVITY_DATE, NBREARN_USER_ID)
                Values
                (trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,1, 
                v_NBREARN_EARN_CODE_OLD,'N',1,sysdate , 'TT_HR_PASS');
                                      
                END IF;
 
             

                FOR fund_loop IN ( select POSN_FUND_CODE,POSN_ORGN_CODE,POSN_ACCT_CODE, POSN_PROPOSED_ACCT_PERCENT , POSN_PROG_CODE
                        from tt_hr_pass.nc_pass_transfunding_r where NC_PASS_TRANS_B_ID = trans_b_rec.TRANS_ID                    
                        )
                LOOP
                  INSERT INTO NBRJLBD (
                  NBRJLBD_PIDM, NBRJLBD_POSN, NBRJLBD_SUFF, NBRJLBD_EFFECTIVE_DATE, 
                  NBRJLBD_PERCENT, NBRJLBD_SALARY_ENC_TO_POST, NBRJLBD_FRINGE_ENC_TO_POST, NBRJLBD_CHANGE_IND, 
                  NBRJLBD_ACTIVITY_DATE,  NBRJLBD_FUND_CODE, 
                  NBRJLBD_ORGN_CODE, NBRJLBD_ACCT_CODE, NBRJLBD_PROG_CODE, NBRJLBD_USER_ID
                  )
                  VALUES(
                  trans_b_rec.PASS_PIDM, trans_b_rec.POSN_NBR, trans_b_rec.PASS_SUFF, trans_b_rec.POSN_EFFECTIVE_DATE,
                  fund_loop.POSN_PROPOSED_ACCT_PERCENT,0,0,'A',
                  sysdate,fund_loop.POSN_FUND_CODE,
                  fund_loop.POSN_ORGN_CODE,fund_loop.POSN_ACCT_CODE,fund_loop.POSN_PROG_CODE,'TT_HR_PASS');  
               END LOOP;  
            
              sql_stmt := 'update TT_HR_PASS.NC_PASS_TRANS_B   SET   TRANS_STATUS = ''E'||''' , '||
              ' EPAF_CREATED_DATE =   '''|| v_date ||''''||
              ' where TRANS_NO =  '''|| pass_trans_no ||'''';

              EXECUTE IMMEDIATE sql_stmt; 
                
               
       END IF;    --IF ( ((v_new_exempt_ind = 'N') AND (v_curr_exempt_ind = 'Y')) AND ((trans_b_rec.PASS_POSN_VACANT_BY_DATE IS NOT NULL) OR (trans_b_rec.PASS_PIDM IS NOT NULL) ) ) THEN


	  	
           select trans_status, posn_nbr,epaf_transaction_no
	       into v_trans_holding_status, v_trans_holding_posn_nbr, v_epaf_transaction_no
	      from TT_HR_PASS.NC_PASS_TRANS_B
	       where TRANS_NO = pass_trans_no;

           IF v_trans_holding_status = 'E' THEN
             P_UPDATE_EPM_PASS_STATUS(pass_trans_no, v_trans_holding_posn_nbr, u_id, v_holding_status);
             IF  v_epaf_transaction_no IS null then
                rtn_flag := null;
             ELSIF v_holding_status = 'success' THEN
		            rtn_flag := 'S'; --The Return Flag is Set to Success if the package is executed successfully
	           ELSIF v_holding_status = 'empty' THEN
	              rtn_flag := 'N'; --The Return Flag is Set to Not Success if the jv records are not submitted
             ELSE
	           rtn_flag := 'E'; --The Return Flag is Set to Error if the package has an error
	           END IF;         
           END IF;
          

        EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                       
                         ROLLBACK TO s_pass_create_epaf;
                         err_msg := ('ERR- '||SUBSTR(SQLERRM, 1,10000)||' LINE - '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                         DBMS_OUTPUT.PUT_LINE(err_msg);
                         /*v_file := 'p_pass_error.xls';
                         wfile_handle := utl_file.fopen ('EPRINT_LOAD_DIR',v_file, 'W');
                         err_msg := 'Process'||chr(9)||'p_create_epaf';
                         utl_file.put_line(wfile_handle,err_msg);
                         err_msg := 'PASS Transaction No'||chr(9)||pass_trans_no;
                         utl_file.put_line(wfile_handle,err_msg);
                         err_msg := 'EPAF Transaction No'||chr(9)||epaf_transaction_no;
                         utl_file.put_line(wfile_handle,err_msg);  */
                        
                         
                         /*utl_file.put_line(wfile_handle,err_msg);
                         
                         rtn_flag := 'E';  
                         DBMS_OUTPUT.PUT_LINE ('EPAF rtn_flag : '||rtn_flag);
                         
                         if utl_file.is_open (wfile_handle) then
                           utl_file.fclose (wfile_handle);
                           DBMS_OUTPUT.PUT_LINE ('Err File Closed : '||v_file);
                         end if;
                         
                         select ttufiscal.pwkmisc.f_get_eprint_repository('HR1')
                         into   v_eprint_user  from   dual;
                         DBMS_OUTPUT.PUT_LINE('eprint_user: '||v_eprint_user);

                          select gjbpseq.nextval
                             into v_one_up
                          from DUAL;

                          GOKEPRT.p_add_report( v_one_up  --1234 -- one-up-number
                                ,'p_pass_error'     -- e-Print Report definition (case sensitive)
                                ,'p_pass_error.xls'          -- actual file name that is located in the EPRINT_LOAD_DIR or alias
                                ,v_eprint_user            -- repository name
                                ,v_eprint_user);          -- user id (same as repository name)
                          DBMS_OUTPUT.PUT_LINE('Sending eprint error report');
                          DBMS_OUTPUT.PUT_LINE (' Completed.');  */
                        insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                        (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                        EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                        EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                        values
                        (sysdate,'PASS',
                        err_msg, 'NWKPASS','p_create_epaf',
                        pass_trans_no,u_id
                        );  
                   
                        END;

--1
END; 

 --------------------------------------------------------------------------------------------
-- OBJECT NAME: p_apwx_reclass_update
-- PRODUCT....: HR
-- USAGE......: Updates Banner Positions and Creates ePAF based on PASS ReClass Transaction
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--  This procedure will create updates Banner Positions and Creates ePAF based on PASS ReClass Transaction
--   
--                                                 
--------------------------------------------------------------------------------------------
PROCEDURE p_apwx_reclass_update
IS

v_rtn_flg                       varchar2(200);

u_id                            varchar2(200);

reclass_error                   EXCEPTION;

CURSOR CURSOR_TRANS_B IS
 select TRANS_NO, TRANS_STATUS, CALC_EFF_DATE from tt_hr_pass.nc_pass_trans_b 
 WHERE TRANS_NO LIKE ('RC%') AND
 TRANS_STATUS = 'A';
 
 CURSOR CURSOR_TRANS_ERR(p_tr_no IN varchar2) IS
  select TRANS_NO, TRANS_STATUS, CALC_EFF_DATE from tt_hr_pass.nc_pass_trans_b 
 WHERE TRANS_NO LIKE ('RC%') AND
 TRANS_STATUS = 'A'
 and trans_no > p_tr_no ;
 
BEGIN
v_rtn_flg := NULL;

u_id := 'Apwx';

  BEGIN
      FOR r1 IN CURSOR_TRANS_B LOOP    
          BEGIN
              
              DBMS_OUTPUT.PUT_LINE('trans_b_rec.PASS_TRANS_NO:  '||r1.TRANS_NO || ' RTN: ' ||NVL(v_rtn_flg,'n/a') );
              
              IF   (r1.CALC_EFF_DATE  IS NOT NULL)  THEN
              
              DBMS_OUTPUT.PUT_LINE('PASS_CALC_EFF_DATE IS '||r1.CALC_EFF_DATE  || ' AND SYSDATE IS '|| sysdate  );
      
               IF (trunc(r1.CALC_EFF_DATE)  <= SYSDATE) THEN
               
                   DBMS_OUTPUT.PUT_LINE('BANNER UPDATE CALLED FOR TRANS NO '||r1.TRANS_NO);
                   
                   p_rc_banner_upd(r1.TRANS_NO, u_id, v_rtn_flg); 
                   
                   DBMS_OUTPUT.PUT_LINE ('Reclass Return Variable '||v_rtn_flg);
                   
                   IF (v_rtn_flg = 'E') THEN
                     
                     DBMS_OUTPUT.PUT_LINE ('RAISE reclass_error');
                     
                     RAISE reclass_error;
                     
                   END IF;
            
               END IF;
      
              END IF;         
                 
                 EXCEPTION
                    WHEN reclass_error THEN
                    DBMS_OUTPUT.PUT_LINE (' CONTINUE ');
                    CONTINUE;
                    
              END;         
      END LOOP;
  END;

END;
--------------------------------------------------------------------------------------------
-- OBJECT NAME: p_update_peaempl
-- PRODUCT....: HR
-- USAGE......: Increment and return ID seq
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--
-- This procedure will update PEAEMPL for a Reclass transaction that happens between exempt and non-exempt positions
--------------------------------------------------------------------------------------------

PROCEDURE p_update_peaempl IS
v_rtn_flg                       varchar2(200);

u_id                            varchar2(200);
v_ipeds_prim                    PAYROLL.PEBEMPL.PEBEMPL_IPEDS_PRIMARY_FUNCTION%TYPE;
v_iped_dent                     PAYROLL.PEBEMPL.PEBEMPL_IPEDS_MED_DENTAL_IND%TYPE;
v_etax_cons                     PAYROLL.PEBEMPL.PEBEMPL_ETAX_CONSENT_IND%TYPE;
v_new_hire                      PAYROLL.PEBEMPL.PEBEMPL_NEW_HIRE_IND%TYPE;
v_1095tx                        PAYROLL.PEBEMPL.PEBEMPL_1095TX_CONSENT_IND%TYPE;
v_ecls_code                     PAYROLL.PEBEMPL.PEBEMPL_ECLS_CODE%TYPE;
v_EMPL_STATUS                   PAYROLL.PEBEMPL.PEBEMPL_EMPL_STATUS%TYPE;
v_ORGN_CODE_HOME                PAYROLL.PEBEMPL.PEBEMPL_ORGN_CODE_HOME%TYPE;
v_LCAT_CODE                     PAYROLL.PEBEMPL.PEBEMPL_LCAT_CODE%TYPE; 
v_BCAT_CODE                     PAYROLL.PEBEMPL.PEBEMPL_BCAT_CODE%TYPE;
v_CURRENT_HIRE_DATE             PAYROLL.PEBEMPL.PEBEMPL_CURRENT_HIRE_DATE%TYPE; 
v_ADJ_SERVICE_DATE              PAYROLL.PEBEMPL.PEBEMPL_ADJ_SERVICE_DATE%TYPE; 
v_FT_PT_IND                     PTRECLS.PTRECLS_INTERNAL_FT_PT_IND%TYPE;   
sql_stmt                        VARCHAR2(2500);
v_PEBEMPL_FLG                   VARCHAR2(1); 
v_PEBEMPL_ECLS_CODE             PAYROLL.PEBEMPL.PEBEMPL_ECLS_CODE%TYPE; 
v_PEBEMPL_LCAT_CODE             PAYROLL.PEBEMPL.PEBEMPL_LCAT_CODE%TYPE; 
v_PEBEMPL_BCAT_CODE             PAYROLL.PEBEMPL.PEBEMPL_BCAT_CODE%TYPE; 
v_PEBEMPL_FT_PT_IND             PAYROLL.PEBEMPL.PEBEMPL_INTERNAL_FT_PT_IND%TYPE; 


CURSOR CURSOR_TRANS_B IS
 select TRANS_NO, TRANS_STATUS, CALC_EFF_DATE, EMPLOYEE_PIDM, POSN_ECLS_CODE  , POSN_LCAT_CODE, POSN_BCAT_CODE
 from tt_hr_pass.nc_pass_trans_b where trans_no like 'RC%' and bnr_upload = 'Y' --and epaf_created_Date  is null 
 and CURR_ECLS_CODE <> POSN_ECLS_CODE and EMPLOYEE_PIDM is not null
 and FUTURE_VACANT is not null and FUTURE_VACANT <> 'Y';


 CURSOR CURSOR_TRANS_FTE IS
 select TRANS_NO, TRANS_STATUS, CALC_EFF_DATE, EMPLOYEE_PIDM, POSN_ECLS_CODE, CURR_POSN_FTE, POSN_FTE , POSN_LCAT_CODE, POSN_BCAT_CODE
 from tt_hr_pass.nc_pass_trans_b where trans_no like 'RC%' and bnr_upload = 'Y' --and epaf_created_Date  is null 
 and CURR_POSN_FTE <> POSN_FTE
  and EMPLOYEE_PIDM is not null  and FUTURE_VACANT is not null and FUTURE_VACANT <> 'Y';
 
BEGIN
v_rtn_flg := NULL;

u_id := 'Apwx';

  BEGIN
  
      FOR r1 IN CURSOR_TRANS_B LOOP
          
          BEGIN
              
              DBMS_OUTPUT.PUT_LINE('trans_b_rec.PASS_TRANS_NO:  '||r1.TRANS_NO || ' RTN: ' ||NVL(v_rtn_flg,'n/a') );
              
              IF   (r1.CALC_EFF_DATE  IS NOT NULL)  THEN
              
              DBMS_OUTPUT.PUT_LINE('PASS_CALC_EFF_DATE IS '||r1.CALC_EFF_DATE  || ' AND SYSDATE IS '|| sysdate  );
      
                   IF (trunc(r1.CALC_EFF_DATE)  <= SYSDATE) THEN
                   
                    DBMS_OUTPUT.PUT_LINE('Update PEAEMPL and PEREHIS '); 

                        select PTRECLS_INTERNAL_FT_PT_IND   into v_FT_PT_IND
                        from PTRECLS where PTRECLS_CODE = r1.POSN_ECLS_CODE;

                        select  PEBEMPL_ECLS_CODE, PEBEMPL_LCAT_CODE, PEBEMPL_BCAT_CODE,  PEBEMPL_INTERNAL_FT_PT_IND
                        into  v_PEBEMPL_ECLS_CODE, v_PEBEMPL_LCAT_CODE,  v_PEBEMPL_BCAT_CODE, v_PEBEMPL_FT_PT_IND
                        from PEBEMPL
                        WHERE   pebempl_pidm = r1.EMPLOYEE_PIDM;
                        
                        sql_stmt := 'UPDATE PAYROLL.PEBEMPL  SET ';
                        
                        IF (r1.POSN_ECLS_CODE  != v_PEBEMPL_ECLS_CODE) then
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_ECLS_CODE = '''|| r1.POSN_ECLS_CODE ||'''';
                             
                        END IF; 
                        
                        IF (r1.POSN_LCAT_CODE  != v_PEBEMPL_LCAT_CODE) then
                          IF (v_PEBEMPL_FLG = 'Y') THEN
                            sql_stmt := sql_stmt||'  , ' ;
                          END IF;
                         
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_LCAT_CODE = '''|| r1.POSN_LCAT_CODE ||'''';
                             
                        END IF; 
                        
                        IF (r1.POSN_BCAT_CODE  != v_PEBEMPL_BCAT_CODE) then
                          IF (v_PEBEMPL_FLG = 'Y') THEN
                            sql_stmt := sql_stmt||'  , ' ;
                          END IF;
                         
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_BCAT_CODE = '''|| r1.POSN_BCAT_CODE ||'''';
                             
                        END IF;
                        
                        IF (v_FT_PT_IND  != v_PEBEMPL_FT_PT_IND) then
                          IF (v_PEBEMPL_FLG = 'Y') THEN
                            sql_stmt := sql_stmt||'  , ' ;
                          END IF;
                         
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_INTERNAL_FT_PT_IND = '''|| v_FT_PT_IND ||'''';
                             
                        END IF;
                        
                        IF (v_PEBEMPL_FLG = 'Y') THEN
                          sql_stmt :=   sql_stmt||'  WHERE PEBEMPL_PIDM = '''|| r1.EMPLOYEE_PIDM ||'''';
                          DBMS_OUTPUT.PUT_LINE('Update: '||sql_stmt); 
                          EXECUTE IMMEDIATE sql_stmt;
                        END IF;
                        
                        /*update PEBEMPL 
                        SET PEBEMPL_ECLS_CODE = r1.POSN_ECLS_CODE ,
                        PEBEMPL_LCAT_CODE     =  r1.POSN_LCAT_CODE ,
                        PEBEMPL_BCAT_CODE     =   r1.POSN_BCAT_CODE
                        where pebempl_pidm = r1.EMPLOYEE_PIDM;*/  
                        
                        select PEBEMPL_IPEDS_PRIMARY_FUNCTION,PEBEMPL_IPEDS_MED_DENTAL_IND,
                        PEBEMPL_ETAX_CONSENT_IND, PEBEMPL_NEW_HIRE_IND,
                        PEBEMPL_1095TX_CONSENT_IND, PEBEMPL_ECLS_CODE, PEBEMPL_EMPL_STATUS, PEBEMPL_ORGN_CODE_HOME, PEBEMPL_LCAT_CODE,  
                        PEBEMPL_BCAT_CODE, PEBEMPL_CURRENT_HIRE_DATE, PEBEMPL_ADJ_SERVICE_DATE 
                        into v_ipeds_prim, v_iped_dent,
                        v_etax_cons, v_new_hire,
                        v_1095tx, v_ecls_code, v_EMPL_STATUS, v_ORGN_CODE_HOME,v_LCAT_CODE, v_BCAT_CODE, 
                        v_CURRENT_HIRE_DATE, v_ADJ_SERVICE_DATE  
                        from pebempl where pebempl_pidm  = r1.EMPLOYEE_PIDM; 
                        
                        insert into perehis(
                        PEREHIS_PIDM, PEREHIS_EFFECTIVE_DATE, PEREHIS_USER_ID,
                        PEREHIS_ACTIVITY_DATE, PEREHIS_IPEDS_PRIMARY_FUNCTION, PEREHIS_IPEDS_MED_DENTAL_IND,
                        PEREHIS_ETAX_CONSENT_IND, PEREHIS_NEW_HIRE_IND, PEREHIS_1095TX_CONSENT_IND,
                        PEREHIS_ECLS_CODE  ,  PEREHIS_EMPL_STATUS, PEREHIS_HOME_ORGN, PEREHIS_LCAT_CODE, PEREHIS_BCAT_CODE,
                        PEREHIS_CURRENT_HIRE_DATE, PEREHIS_ADJ_SERVICE_DATE
                        )
                        values (
                        r1.EMPLOYEE_PIDM,r1.CALC_EFF_DATE, 'TT_HR_PASS',
                        sysdate, v_ipeds_prim,v_iped_dent,
                        v_etax_cons, v_new_hire,v_1095tx, 
                        v_ecls_code,  v_EMPL_STATUS, v_ORGN_CODE_HOME,v_LCAT_CODE, v_BCAT_CODE, 
                        v_CURRENT_HIRE_DATE, v_ADJ_SERVICE_DATE
                        );  
                
                   END IF;
      
              END IF;         
                 
            EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                         
                         err_msg := 'ERR -' ||SQLERRM ||' LINE -'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                         DBMS_OUTPUT.PUT_LINE(err_msg);
                         
                         insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','p_update_peaempl',
                          r1.TRANS_NO,'apwx'
                          );
                         
                        END;
            END; 
                       
      END LOOP;
      
  END;
  
  FOR trans_fte_1 IN CURSOR_TRANS_FTE LOOP
          
          BEGIN
              
              DBMS_OUTPUT.PUT_LINE('trans_b_rec.PASS_TRANS_NO:  '||trans_fte_1.TRANS_NO || ' RTN: ' ||NVL(v_rtn_flg,'n/a') );
              
              IF   (trans_fte_1.CALC_EFF_DATE  IS NOT NULL)  THEN
              
              DBMS_OUTPUT.PUT_LINE('PASS_CALC_EFF_DATE IS '||trans_fte_1.CALC_EFF_DATE  || ' AND SYSDATE IS '|| sysdate  );
              
                   select PTRECLS_INTERNAL_FT_PT_IND   into v_FT_PT_IND
                   from PTRECLS where PTRECLS_CODE = trans_fte_1.POSN_ECLS_CODE;
      
                   IF ( trunc(trans_fte_1.CALC_EFF_DATE)  <= SYSDATE ) THEN
                   
                    DBMS_OUTPUT.PUT_LINE('Update PEAEMPL and PEREHIS '); 
                    
                        select  PEBEMPL_ECLS_CODE, PEBEMPL_LCAT_CODE, PEBEMPL_BCAT_CODE,  PEBEMPL_INTERNAL_FT_PT_IND
                        into  v_PEBEMPL_ECLS_CODE, v_PEBEMPL_LCAT_CODE,  v_PEBEMPL_BCAT_CODE, v_PEBEMPL_FT_PT_IND
                        from PEBEMPL
                        WHERE   pebempl_pidm = trans_fte_1.EMPLOYEE_PIDM;
                        
                        sql_stmt := 'UPDATE PAYROLL.PEBEMPL  SET ';
                        
                        IF (trans_fte_1.POSN_ECLS_CODE  != v_PEBEMPL_ECLS_CODE) then
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_ECLS_CODE = '''|| trans_fte_1.POSN_ECLS_CODE ||'''';
                             
                        END IF; 
                        
                        IF (trans_fte_1.POSN_LCAT_CODE  != v_PEBEMPL_LCAT_CODE) then
                          IF (v_PEBEMPL_FLG = 'Y') THEN
                            sql_stmt := sql_stmt||'  , ';
                          END IF;
                         
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_LCAT_CODE = '''|| trans_fte_1.POSN_LCAT_CODE ||'''';
                             
                        END IF; 
                        
                        IF (trans_fte_1.POSN_BCAT_CODE  != v_PEBEMPL_BCAT_CODE) then
                          IF (v_PEBEMPL_FLG = 'Y') THEN
                            sql_stmt := sql_stmt||'  , ';
                          END IF;
                         
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_BCAT_CODE = '''|| trans_fte_1.POSN_BCAT_CODE ||'''';
                             
                        END IF;
                        
                        IF (v_FT_PT_IND  != v_PEBEMPL_FT_PT_IND) then
                          IF (v_PEBEMPL_FLG = 'Y') THEN
                            sql_stmt := sql_stmt||'  , ';
                          END IF;
                         
                          v_PEBEMPL_FLG := 'Y';
                                        
                      	  sql_stmt := sql_stmt||'  PEBEMPL_INTERNAL_FT_PT_IND = '''|| v_FT_PT_IND ||'''';
                             
                        END IF;
                        
                        IF (v_PEBEMPL_FLG = 'Y') THEN
                          sql_stmt :=   sql_stmt||'  WHERE  PEBEMPL_PIDM = '''|| trans_fte_1.EMPLOYEE_PIDM ||'''';
                          DBMS_OUTPUT.PUT_LINE('Update: '||sql_stmt); 
                          EXECUTE IMMEDIATE sql_stmt;
                        END IF;
                        
                        select PEBEMPL_IPEDS_PRIMARY_FUNCTION,PEBEMPL_IPEDS_MED_DENTAL_IND,
                        PEBEMPL_ETAX_CONSENT_IND, PEBEMPL_NEW_HIRE_IND,
                        PEBEMPL_1095TX_CONSENT_IND, PEBEMPL_ECLS_CODE, PEBEMPL_EMPL_STATUS, PEBEMPL_ORGN_CODE_HOME, PEBEMPL_LCAT_CODE,  
                        PEBEMPL_BCAT_CODE, PEBEMPL_CURRENT_HIRE_DATE, PEBEMPL_ADJ_SERVICE_DATE 
                        into v_ipeds_prim, v_iped_dent,
                        v_etax_cons, v_new_hire,
                        v_1095tx, v_ecls_code, v_EMPL_STATUS, v_ORGN_CODE_HOME,v_LCAT_CODE, v_BCAT_CODE, 
                        v_CURRENT_HIRE_DATE, v_ADJ_SERVICE_DATE  
                        from pebempl where pebempl_pidm  = trans_fte_1.EMPLOYEE_PIDM; 
                        
                        insert into perehis(
                        PEREHIS_PIDM, PEREHIS_EFFECTIVE_DATE, PEREHIS_USER_ID,
                        PEREHIS_ACTIVITY_DATE, PEREHIS_IPEDS_PRIMARY_FUNCTION, PEREHIS_IPEDS_MED_DENTAL_IND,
                        PEREHIS_ETAX_CONSENT_IND, PEREHIS_NEW_HIRE_IND, PEREHIS_1095TX_CONSENT_IND,
                        PEREHIS_ECLS_CODE  ,  PEREHIS_EMPL_STATUS, PEREHIS_HOME_ORGN, PEREHIS_LCAT_CODE, PEREHIS_BCAT_CODE,
                        PEREHIS_CURRENT_HIRE_DATE, PEREHIS_ADJ_SERVICE_DATE
                        )
                        values (
                        trans_fte_1.EMPLOYEE_PIDM,trans_fte_1.CALC_EFF_DATE, 'TT_HR_PASS',
                        sysdate, v_ipeds_prim,v_iped_dent,
                        v_etax_cons, v_new_hire,v_1095tx, 
                        v_ecls_code, v_EMPL_STATUS, v_ORGN_CODE_HOME,v_LCAT_CODE, v_BCAT_CODE, 
                        v_CURRENT_HIRE_DATE, v_ADJ_SERVICE_DATE
                        );  
                        
                        update tt_hr_pass.nc_pass_trans_b
                        set EPAF_CREATED_DATE = sysdate
                        where trans_no = trans_fte_1.TRANS_NO;  
                
                   END IF;
      
              END IF;         
                 
            EXCEPTION
                  WHEN OTHERS THEN -- record error and stop

                       DECLARE
                       err_msg VARCHAR2(30000);
                       BEGIN
                         
                         err_msg :=  'ERR -' ||SQLERRM ||' LINE -'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                         DBMS_OUTPUT.PUT_LINE(err_msg);
                         insert into TT_HR_PASS.NC_PASS_EXCEPTION_B
                          (EXCEPTION_ACTIVITY_DATE, EXCEPTION_APP, 
                          EXCEPTION_MESSAGE, EXCEPTION_METHOD, EXCEPTION_PAGE,
                          EXCEPTION_TRANS_NO, EXCEPTION_USER_ID)
                          values
                          (sysdate,'PASS',
                          err_msg, 'NWKPASS','p_update_peaempl',
                          trans_fte_1.TRANS_NO,'apwx'
                          );
                         
                        END;
            END; 
                       
  END LOOP;
END;
--------------------------------------------------------------------------------------------
-- OBJECT NAME: p_update_banner_EP
-- PRODUCT....: HR
-- USAGE......: Increment and return ID seq
-- COPYRIGHT..: Texas Tech University
-- AUTHOR     : Sudarsan R
--
-- DESCRIPTION:
--
-- This procedure will update Banner and create EPAF for filled position Reclass of El Paso (Chart E)
--------------------------------------------------------------------------------------------


PROCEDURE p_update_banner_EP IS
v_cnt_payroll_date          NUMBER;
--v_ptrcaln_start_date PTRCALN.PTRCALN_START_DATE%type;
v_payroll_start_date        ttufiscal.pwbpyst.PWBPYST_START_DATE%type;
v_ep_flag                   varchar2(1);
v_rtn_flg                   varchar2(1);
type string_list is table of varchar2(2);
pict_list string_list := string_list('SM', 'MN');
BEGIN
  FOR i in pict_list.first .. pict_list.last LOOP 
      
      dbms_output.put_line('pict_code: ' || pict_list(i)); 
      
      select count(*) into v_cnt_payroll_date
            from ttufiscal.pwbpyst
            where PWBPYST_PICT_CODE    = pict_list(i)
            and PWBPYST_COMPLETE       = 'N'
            and PWBPYST_START_DATE <= sysdate;

            IF(v_cnt_payroll_date > 0) THEN     --END IF;   --IF(v_cnt_payroll_date > 0) THEN

                select max(PWBPYST_START_DATE)
                into v_payroll_start_date
                from ttufiscal.pwbpyst
                where PWBPYST_PICT_CODE    = pict_list(i)
                and PWBPYST_COMPLETE       = 'N'
                and PWBPYST_START_DATE    <= sysdate; 
                

                
                FOR rec in (select trans_no, employee_pidm,posn_coas_code, future_vacant, approval_date, bnr_upload, calc_eff_date 
                from tt_hr_pass.nc_pass_trans_b  where trans_no like 'RC%' 
                and posn_coas_code like 'E'  and bnr_upload is null and trunc(calc_eff_date) <= v_payroll_start_date) 
                LOOP 
                
                    dbms_output.put_line('trans_no: ' || rec.trans_no); 
                    
                    v_ep_flag :=  getElPasoRCFlag(rec.trans_no,  rec.posn_coas_code, rec.employee_pidm, rec.future_vacant, rec.approval_date,
                                                  rec.bnr_upload, rec.calc_eff_date );
                    dbms_output.put_line(' v_ep_flag: '||v_ep_flag);                               
                    IF (v_ep_flag = 'N' ) THEN 
                    p_rc_banner_upd(rec.trans_no,'Apwx', v_rtn_flg); 
                    dbms_output.put_line('p_rc_banner_upd: ' || v_rtn_flg);
                    
                    p_create_epaf(rec.trans_no,'Apwx', v_rtn_flg); 
                    dbms_output.put_line('p_create_epaf: ' || v_rtn_flg);
                    END IF;  
                
                END LOOP;                              

            END IF;   --IF(v_cnt_payroll_date > 0) THEN
      
  END LOOP; 
            
END;

END;
/


GRANT EXECUTE ON TT_HR_PASS.NWKPASS TO BANINST1 WITH GRANT OPTION;
/

