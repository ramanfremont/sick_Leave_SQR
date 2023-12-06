

    !--------------------------------------------------------------------
    !--Selects info from Job, most specifically Paygroup.  Paygroup will-
    !--control the order in which accruals happen.                      -
    !--------------------------------------------------------------------
SELECT
    J.EMPLID,    
    J.EMPL_RCD,
    J.EFFDT,
    /*TO_CHAR(J.EFFDT,'YYYY') AS EFFDT_YEAR  RAMAN */
    J.PAYGROUP,  
    J.DEPTID,    
    J.COMPANY,
    J.REG_TEMP,
    /*J.FULL_PART_TIME,*/
    J.STD_HOURS,
    J.HOURLY_RT, 
    N.NAME					
FROM 
    PS_JOB J
JOIN 
    PS_NAMES N ON J.EMPLID = N.EMPLID
WHERE 
    J.REG_TEMP = 'T' AND J.COMPANY = 'COF'
    AND J.EFFDT  = (SELECT MAX(A_ED.EFFDT)
                    FROM PS_JOB A_ED
                   WHERE J.EMPLID     = A_ED.EMPLID
                     AND J.EMPL_RCD  = A_ED.EMPL_RCD
                     AND A_ED.EFFDT  <= '11-OCT-02') /*added date removed variable*/
    AND J.EFFSEQ = (SELECT MAX(A_ES.EFFSEQ)
                    FROM PS_JOB A_ES
                   WHERE J.EMPLID    = A_ES.EMPLID
                     AND J.EMPL_RCD = A_ES.EMPL_RCD
                     AND J.EFFDT     = A_ES.EFFDT)		
    AND N.NAME_TYPE = 'PRI'			  
    AND N.EFFDT = (SELECT MAX(N_ED.EFFDT) FROM PS_NAMES N_ED	
                 WHERE N.EMPLID = N_ED.EMPLID		
                 AND N.NAME_TYPE = N_ED.NAME_TYPE	
                 AND N_ED.EFFDT <= '11-OCT-02')  	/*added date removed variable*/
ORDER BY 
    J.PAYGROUP, N.NAME;


/* General command
SELECT * 
FROM PS_NAMES;
*/

SELECT REG_TEMP = 'T' and FULL_PART_TIME = 'P'
FROM PS_JOB A_ED;

SELECT * 
FROM PS_LEAVE_RATE_TBL LRT
WHERE BENEFIT_PLAN = 'CASICK' AND PLAN_TYPE = '50'

SELECT COLUMN_NAME, DATA_TYPE 
FROM ALL_TAB_COLUMNS 
WHERE TABLE_NAME = 'PS_LEAVE_RATE_TBL' AND COLUMN_NAME = 'PLAN_TYPE';

end-select

Do Update-Leave-Plan-Table			! Take this out for testing

Display #Empcount

end-procedure    !Main

/*RAMAN
!***********************************************************************
Begin-procedure Get-Personal-Data
!***********************************************************************

    !--------------------------------------------------------------------
    !--Gets Name and Hire Date.  Name will be used in Report showing    -
    !--Current Accrual Info.  Hire Date will be used in calculating     -
    !--proration for management leave for new hires                     -
    !--------------------------------------------------------------------



Begin- 
Select

PERS.NAME

  --Let $Name = &PERS.NAME

From PS_PERSONAL_DATA PERS

Where PERS.EMPLID = $Emplid
 
end-select

! Show '              Employee Name: ' $Name

end-procedure

!***********************************************************************
Begin-Procedure Get-Benefit-Program
!***********************************************************************
Begin-Select

B.BENEFIT_PROGRAM
	Let $BenProg = &B.BENEFIT_PROGRAM

From  PS_BEN_PROG_PARTIC   B

Where B.EMPLID = $Emplid
      AND B.EMPL_RCD = #EmplRcd
     AND B.EFFDT = (SELECT MAX(BP.EFFDT)
                    FROM PS_BEN_PROG_PARTIC BP
                    WHERE (BP.EMPLID = B.EMPLID
                      AND BP.EMPL_RCD = B.EMPL_RCD
                      AND BP.EFFDT < $AccrPrcDt))
                      
End-Select

End-Procedure Get-Benefit-Program

!***********************************************************************
Begin-Procedure Get-FTE-Status
!***********************************************************************

    !--------------------------------------------------------------------
    !--Used to figure out if employee is on a modified schedule.  If    -
    !--Employee is on a modified schedule standard hours will be        -
    !--increased to ensure that modified employees will change accrual  -
    !--levels at the same increments as Full-Time Employees             -
    !--------------------------------------------------------------------

If #StdHrs < 40
   let $Modified          = 'Y'
   let #ModifyPct         = #StdHrs/40
   
   If #StdHrs <> 0
      let #StdHrs_MultFactor = 40/#StdHrs         !KAM100200
	else                                          !KAM100200
	  let #stdHrs_MultFactor = 0                  !KAM100200
   end-if                                         !KAM100200
 else
   let $Modified          = 'N'
!   let #ModifyPCT         = 100                   !DH060704
   let #ModifyPCT         = 1.0                    !DH060704
   let #StdHrs_MultFactor = 1.0
end-if

!   Show '                  Modified = ' $Modified
!   Show '          Modified Percent = ' #ModifyPCT
!   Show 'Standard Hours Mult Factor = ' #StdHrs_MultFactor

end-procedure	!Get-FTE-Status


!***********************************************************************
Begin-Procedure Reset-Accrual-Variables
!***********************************************************************
*/
	!--------------------------------------------------------------------
	!--Resets variables for new employee                                -
	!--------------------------------------------------------------------


   Let #Rate         = 0
   Let #OldAccrl     = 0
   Let $Plntype      = ''
   Let $BenPln       = ''
   Let $OldDt        = ''
   Let #SvcHrs       = 0
   Let #UnprcSvcHrs  = 0
   Let #Carryover    = 0
   Let #EarnedYTD    = 0
   Let #TakenYTD     = 0
   Let #AdjustYTD    = 0
   Let #BoughtYTD    = 0
   Let #SoldYTD      = 0
   Let #TakenUnproc  = 0
   Let #AdjustUnproc = 0
   Let #BoughtUnproc = 0
   Let #SoldUnproc   = 0
   Let #NewSvcHrs    = 0
   Let #LvBal        = 0
   Let #OldLv_Bal    = 0
   Let #NewCarryover = 0
   Let #NewTakenYTD  = 0
   Let #NewAdjustYTD = 0
   Let #NewBoughtYTD = 0
   Let #NewSoldYTD   = 0
   Let #Accrl        = 0                      
 
end-procedure	!Reset-Accrual-Variables

!***********************************************************************
Begin-Procedure Get-Plan-Type-Order
!***********************************************************************

    Let $Invalid_Date = 'N'

    !--------------------------------------------------------------------
    !--This controls the order in which accruals are processed.  This   -
    !--hard codes the order in which plan type is to accrue first.  The -
    !--order is based on Paygroup (assumption that this is the same as  -
    !--Bargaining Unit).  
    !--------------------------------------------------------------------
 Evaluate $Paygroup

  
   When = 'FMS' 
       
       Let $Benpln = ' '
       Do Reset-Accrual-Variables                                                                                                  
       Let $Plntype = '5X'                                  
         Do Get-Benefit-Plan                                 
!         Show '           Benefit Plan = '$Benpln
         Do Select-Leave-Plan-Date
         If $Mode = 'FISCAL_YEAR' and $Invalid_Date = 'N' and $Benpln <> ''
            Do Get-NAF-Carryover-Balance
            Do Get-Service-Hrs
            Do Get-Accrual-Rate
            Do Get-NAF-New-Accruals
            Do Actual-Insert-Leave-Accrual
            Do Update-Comp-Leav-Tbl                                        	   
         End-if
   

   Break
   When = 'FAC'
  ! When = 'TMR'					! chi 070816
   When = 'PTA'
   When = 'OE3'
   When = 'CON' 

         Let $Benpln = ' '
         Do Reset-Accrual-Variables
         Let $Plntype = '5T'                                  
         Do Get-Benefit-Plan                                 
  !       Show '           Benefit Plan = '$Benpln
         Do Select-Leave-Plan-Date
         If $Mode = 'FISCAL_YEAR' and $Invalid_Date = 'N' and $Benpln <> ''
            Do Get-NAF-Carryover-Balance
            Do Get-Service-Hrs
            Do Get-Accrual-Rate
            Do Get-NAF-New-Accruals
            Do Actual-Insert-Leave-Accrual
            Do Update-Comp-Leav-Tbl                                        
         End-if                                                                                                  
   Break

 !  When = 'FAM'				! CE070505
   When = 'SA'
     if $BenProg = 'FAM'
         Let $Benpln = ' '
         Do Reset-Accrual-Variables
         Let $Plntype = '5X'                                  
         Do Get-Benefit-Plan                                 
  !       Show '           Benefit Plan = '$Benpln
         Do Select-Leave-Plan-Date
         If $Mode = 'FISCAL_YEAR' and $Invalid_Date = 'N' and $Benpln <> ''
            Do Get-NAF-Carryover-Balance
            Do Get-Service-Hrs
            Do Get-Accrual-Rate
            Do Get-NAF-New-Accruals
            Do Actual-Insert-Leave-Accrual
            Do Update-Comp-Leav-Tbl                                        
         End-if
     End-if
 
   Break
   When = 'FAM'	
 !  When = 'SA'						! CE070505
 !    if $BenProg = 'FAM'
         Let $Benpln = ' '
         Do Reset-Accrual-Variables
         Let $Plntype = '5X'                                  
         Do Get-Benefit-Plan                                 
  !       Show '           Benefit Plan = '$Benpln
         Do Select-Leave-Plan-Date
         If $Mode = 'FISCAL_YEAR' and $Invalid_Date = 'N' and $Benpln <> ''
            Do Get-NAF-Carryover-Balance
            Do Get-Service-Hrs
            Do Get-Accrual-Rate
            Do Get-NAF-New-Accruals
            Do Actual-Insert-Leave-Accrual
            Do Update-Comp-Leav-Tbl                                        
         End-if
 !    End-if
 
   Break
   When = 'UFO'
   When = 'UME'                                    !DH060704
   When = 'CA'
   When = 'CM'
         Let $Benpln = ' '
         Do Reset-Accrual-Variables
         Let $Plntype = '5X'                                  
         Do Get-Benefit-Plan                                 
 !        Show '           Benefit Plan = '$Benpln
         Do Select-Leave-Plan-Date
         If $Mode = 'FISCAL_YEAR' and $Invalid_Date = 'N' and $Benpln <> ''
            Do Get-NAF-Carryover-Balance
            Do Get-Service-Hrs
            Do Get-Accrual-Rate
            Do Get-NAF-New-Accruals
            Do Actual-Insert-Leave-Accrual
            Do Update-Comp-Leav-Tbl                                        
         End-if
 
   Break

   When-Other
   Break
 End-evaluate
end-procedure 	!Get-Plan-Type-Order


!***********************************************************************
Begin-Procedure Get-Benefit-Plan
!***********************************************************************

    !--------------------------------------------------------------------
    !--This is used to determine the benefit plan for the specified     -
    !--plan type.  This routine is called several times from several    -
    !--different locations.  The benefit plan is needed in order to     -
    !--find the accrual rate from the LEAVE_PLAN_TBL                    -
    !--------------------------------------------------------------------
    Let $Benpln      = ''
    
Begin-Select

LP.EMPLID
LP.EMPL_RCD
LP.PLAN_TYPE
LP.BENEFIT_PLAN  

	Let	$Benpln  = &LP.BENEFIT_PLAN
!      Display 'Benefit Plan should go here'

From PS_LEAVE_PLAN LP
Where LP.EMPLID      = $Emplid
  AND LP.EMPL_RCD   = #Emplrcd
  AND LP.PLAN_TYPE   = $Plntype
  AND LP.EFFDT       = (Select Max(ED.EFFDT)
                     From PS_LEAVE_PLAN ED
                     Where LP.EMPLID         = ED.EMPLID
                           And LP.EMPL_RCD      = ED.EMPL_RCD
                           And LP.PLAN_TYPE      = ED.PLAN_TYPE
                           And LP.BENEFIT_NBR       = ED.BENEFIT_NBR
                           And ED.EFFDT       <= $AccrPrcDt
                           And LP.COVERAGE_ELECT = 'E')

end-select

end-procedure    !Get-Benefit-Plan


!***********************************************************************
Begin-Procedure Get-Service-Hrs
!***********************************************************************


Do Get-Service-Hrs-If-Row-Exists        !KAM100200
    !--------------------------------------------------------------------
    !--This gets service hours.  Service hours will be used to determine-
    !--if the employee will reach the next accrual level.  This will    -
    !--also find the accrual rate and calculate the vacation bank       -
    !--maximum.                                                         -
    !--------------------------------------------------------------------

Begin-Select

LA.SERVICE_HRS
LA.SERVICE_HRS_UNPROC

   Let #Svchrs      = &LA.SERVICE_HRS
   Let #UnprcSvcHrs = &LA.SERVICE_HRS_UNPROC
   Let #NewSvcHrs   = #Svchrs + #UnprcSvcHrs
 ! Show '               Old Svc Hrs = ' #Svchrs
 ! Show '            Unproc Svc Hrs = ' #UnprcSvcHrs
 ! Show '               New Svc Hrs = ' #NewSvcHrs
  

FROM PS_LEAVE_ACCRUAL LA
WHERE LA.EMPLID          = $Emplid
  AND LA.EMPL_RCD        = #Emplrcd
  AND LA.PLAN_TYPE       = $Plntype
  AND LA.COMPANY         = $Company
  [$Sql_Condition_SvcHrs]                                                  
 
end-select

End-Procedure	!Get-Service-Hrs

!***********************************************************************
Begin-Procedure Get-Service-Hrs-If-Row-Exists               
!***********************************************************************

    !--------------------------------------------------------------------
    !--Determines whether a row exists with an accrual proc date or not -
    !--------------------------------------------------------------------

let $service_hrs_row_exists = 'N'

Begin-Select

LA_row.SERVICE_HRS
LA_row.SERVICE_HRS_UNPROC

   let $service_hrs_row_exists = 'Y'

 FROM PS_LEAVE_ACCRUAL LA_row
WHERE LA_row.EMPLID          = $Emplid
  AND LA_row.EMPL_RCD       = #Emplrcd
  AND LA_row.PLAN_TYPE       = $Plntype
  AND LA_row.COMPANY         = $Company
  AND LA_row.ACCRUAL_PROC_DT = (SELECT MAX(LA_row1.ACCRUAL_PROC_DT)                
                                  FROM PS_LEAVE_ACCRUAL LA_row1
                                 WHERE LA_row1.EMPLID          = $Emplid
                                   AND LA_row1.EMPL_RCD       = #Emplrcd
                                   AND LA_row1.COMPANY         = LA_row.COMPANY
                                   AND LA_row1.PLAN_TYPE       = $Plntype)

end-select

If $service_hrs_row_exists = 'N'
   Let $Sql_Condition_SvcHrs = 'AND LA.ACCRUAL_PROC_DT IS NULL'             
 ELSE
   Let $Sql_Condition_SvcHrs = 'AND LA.ACCRUAL_PROC_DT = (SELECT MAX(LA1.ACCRUAL_PROC_DT)                  
                                                              FROM PS_LEAVE_ACCRUAL LA1
                                                             WHERE LA1.EMPLID          = LA.Emplid         
                                                               AND LA1.EMPL_RCD       = LA.Empl_Rcd      
                                                               AND LA1.COMPANY         = LA.COMPANY
                                                               AND LA1.PLAN_TYPE       = LA.PLAN_TYPE)'    
end-if

!show '        $Sql_Condition_SvcHrs = ' $Sql_Condition_SvcHrs

End-Procedure	!Get-Service-Hrs-If-Row-Exists



!***********************************************************************
Begin-Procedure Get-Accrual-Rate
!***********************************************************************

    !--------------------------------------------------------------------
    !--This is used to get the accrual rate from the LEAVE_PLAN_TBL     -
    !--based on the benefit plan.
    !--------------------------------------------------------------------


Begin-Select

LRT.HOURS_EARNED

   Let #Rate = &LRT.HOURS_EARNED
   

FROM PS_LEAVE_RATE_TBL LRT
WHERE LRT.PLAN_TYPE              = $Plntype
  AND LRT.BENEFIT_PLAN           = $Benpln
  AND SERVICE_INTERVALS          = (SELECT MAX(LRT2.SERVICE_INTERVALS)
                                      FROM PS_LEAVE_RATE_TBL LRT2
                                     WHERE SERVICE_INTERVALS <= #NewSvcHrs
                                       AND LRT.PLAN_TYPE     = LRT2.PLAN_TYPE
                                       AND LRT.BENEFIT_PLAN  = LRT2.BENEFIT_PLAN
                                       AND LRT2.EFFDT       <= $AccrPrcDt)
!                                       AND LRT2.EFFDT       = LRT.EFFDT)					! CE090209						   

  AND LRT.EFFDT                  = (SELECT MAX(LRT1.EFFDT)
                                      FROM PS_LEAVE_RATE_TBL LRT1
                                     WHERE LRT.PLAN_TYPE     = LRT1.PLAN_TYPE
                                       AND LRT.BENEFIT_PLAN  = LRT1.BENEFIT_PLAN
                                       AND LRT1.EFFDT       <= $AccrPrcDt)

end-select


End-Procedure	!Get-Accrual-Rate

!***********************************************************************
Begin-Procedure Select-Leave-Plan-Date
!***********************************************************************

    !--------------------------------------------------------------------
    !--Select last Accrual Process Date used before this update 
    !--------------------------------------------------------------------


Begin-Select

L.ACCRUAL_PROC_DT

  Let $LastAccrualDt = &L.ACCRUAL_PROC_DT
FROM
PS_LEAVE_PLAN_TBL L
 
 WHERE L.PLAN_TYPE = $Plntype
   AND L.EFFDT = (SELECT MAX(L_A.EFFDT)
                      FROM PS_LEAVE_PLAN_TBL L_A
                     WHERE L.PLAN_TYPE    = L_A.PLAN_TYPE
                       AND L.BENEFIT_PLAN = L_A.BENEFIT_PLAN
                      AND L_A.EFFDT     <= $AsOfToday)
          
end-select

  Do Format-DateTime($LastAccrualDt, $LAccrDt, {DEFCMP}, '', '')
  Do Format-DateTime($AccrPrcDt, $AccrDt, {DEFCMP}, '', '')
   if $AccrDt <= $LAccrDt
      Let $Invalid_Date = 'Y'
      Print 'Accrual Process Date should be greater than Last Accrual Process Date.' (+2,) center
      Print 'Check to see if Non-Accruable Leave Allocation has already been run.' (+1,) center
   end-if

end-procedure	!Select-Leave-Plan-Date



!***********************************************************************
Begin-Procedure Check-Accrual-Date
!***********************************************************************

let $row_exists = 'N'

begin-Select

LA9.ACCRUAL_PROC_DT,
LA9.SERVICE_HRS,
LA9.HRS_CARRYOVER,
LA9.HRS_EARNED_YTD,
LA9.HRS_TAKEN_YTD,
LA9.HRS_ADJUST_YTD,
LA9.HRS_BOUGHT_YTD,
LA9.HRS_SOLD_YTD,
LA9.SERVICE_HRS_UNPROC,
LA9.HRS_TAKEN_UNPROC,
LA9.HRS_ADJUST_UNPROC,
LA9.HRS_BOUGHT_UNPROC,
LA9.HRS_SOLD_UNPROC

	let $row_exists = 'Y'

FROM PS_LEAVE_ACCRUAL LA9

WHERE LA9.EMPLID          = $Emplid
  AND LA9.EMPL_RCD       = #Emplrcd
  AND LA9.COMPANY         = $Company
  AND LA9.PLAN_TYPE       = $Plntype
  AND LA9.ACCRUAL_PROC_DT = (SELECT MAX(LA3.ACCRUAL_PROC_DT)
 	                               FROM PS_LEAVE_ACCRUAL LA3
                                  WHERE LA3.EMPLID          = LA9.EMPLID
                                    AND LA3.EMPL_RCD       = LA9.EMPL_RCD
                                    AND LA3.COMPANY         = LA9.COMPANY 
                                    AND LA3.PLAN_TYPE       = LA9.PLAN_TYPE)
									
end-select

if $row_exists = 'N'
      let $sql_condition_NAF = 'AND LA5.ACCRUAL_PROC_DT IS NULL'
else
      let $sql_condition_NAF = 'AND LA5.ACCRUAL_PROC_DT = (SELECT MAX(LA4.ACCRUAL_PROC_DT)
 	                               FROM PS_LEAVE_ACCRUAL LA4
                                     WHERE LA4.EMPLID          = LA5.EMPLID
                                    AND LA4.EMPL_RCD       = LA5.EMPL_RCD
                                    AND LA4.COMPANY         = LA5.COMPANY 
                                    AND LA4.PLAN_TYPE       = LA5.PLAN_TYPE)'
end-if

!SHOW '             SQL CONDITION = ' $sql_condition_NAF


end-procedure


!***********************************************************************
Begin-Procedure Actual-Insert-Leave-Accrual
!***********************************************************************


Begin-SQL

Insert into PS_LEAVE_ACCRUAL
( EMPLID
, EMPL_RCD
, COMPANY
, PLAN_TYPE
, ACCRUAL_PROC_DT
, SERVICE_HRS
, HRS_CARRYOVER
, HRS_EARNED_YTD
, HRS_TAKEN_YTD
, HRS_ADJUST_YTD
, HRS_BOUGHT_YTD
, HRS_SOLD_YTD
, SERVICE_HRS_UNPROC
, HRS_TAKEN_UNPROC
, HRS_ADJUST_UNPROC
, HRS_BOUGHT_UNPROC
, HRS_SOLD_UNPROC)

Values
( $Emplid
, #Emplrcd
, $Company
, $Plntype
, $AccrPrcDt
, #NewSvcHrs
, #NewCarryover
, #NewEarnedYTD
, #NewTakenYTD
, #NewAdjustYTD
, #NewBoughtYTD
, #NewSoldYTD
, 0
, 0
, 0
, 0
, 0)

end-sql

If $Plntype <> '5W'                                        
   Do Print-Data
end-if	                                                  

End-Procedure	!Actual-Insert-Leave-Accruals

!*********************************************************************** 
Begin-Procedure Update-Comp-Leav-Tbl                                     
!*********************************************************************** 
   
    !------------------------------------------------------------------- 
    !--Update Comp-Leav-Tbl with New Leave Balances for Validating Time  
    !--and Labor                                                         
    !------------------------------------------------------------------- 

  Do Check-Comp-Plan

BEGIN-SQL                                                                

UPDATE PS_TL_COMPLEAV_TBL                                               
 SET END_BAL = #NewBal,                                                   
     TL_QUANTITY = 0                                                     
WHERE EMPLID = $Emplid                                                   
 AND EMPL_RCD = #Emplrcd                                                 
 AND COMP_TIME_PLAN = $Plntype                                          

END-SQL                                                                  

End-Procedure Update-Comp-Leav-Tbl

!***********************************************************************  
Begin-Procedure Check-Comp-Plan                                           
!***********************************************************************  
   
    !-------------------------------------------------------------------  
    !--Check Comp-Leav-Tbl to see if row exists with balance for      
    !--Plan. If row exists update, else display emplid                       
    !-------------------------------------------------------------------  

   Let $Planexist = 'N'

BEGIN-SELECT                                                             

CL.END_BAL                                                                
CL.TL_QUANTITY                                                          
   Let $Planexist = 'Y'                                              

FROM PS_TL_COMPLEAV_TBL CL                                               

WHERE EMPLID = $Emplid                                                   
 AND EMPL_RCD = #Emplrcd                                                 
 AND COMP_TIME_PLAN = $Plntype                                           

END-SELECT                                                               

  If $Planexist = 'N'
    Display 'No Leave Plan in Comp-time table'
    Display $Emplid
    DO INSERT-COMPLEAV-TBL				! CE051106
  End-if

End-Procedure Check-Comp-Plan


!***********************************************************************
Begin-Procedure INSERT-COMPLEAV-TBL                   ! CE051106             
!***********************************************************************

BEGIN-SQL

INSERT INTO PS_TL_COMPLEAV_TBL
 (EMPLID
 ,EMPL_RCD
 ,DUR   
 ,TRC
 ,COMP_LEAV_IND
 ,COMP_TIME_PLAN
 ,EXP_DT
 ,TL_QUANTITY
 ,END_BAL)
Values
 ($Emplid
 ,#Emplrcd
 ,$AccrPrcDt
 ,'LTKN'
 ,'LTKN'
 ,$Plntype
 ,$AccrPrcDt
 ,0
 ,#NewBal)

END-SQL

End-Procedure Insert-COMPLEAV-TBL


!************************************************************************
Begin-Procedure Check-For-New-Fiscal-Year
!************************************************************************

  Let $JUL1 = '01-JUL-'||&CURRENT_YEAR				

  Do Convert-To-DTU-Date($JUL1, $dtu-date)
  Do dtu-subtract-days($dtu-date, 13, $dtu-date-out)
!  Do dtu-subtract-days($dtu-date, 32, $dtu-date-out)  !For Testing Only
  Do Convert-From-DTU-Date($dtu-date-out, $beg_date_FY_accrual_proc)
  Do Format-DateTime($beg_date_FY_accrual_proc, $begdate, {DEFYMD}, '', '')

  Let $end_date_FY_accrual_proc = $JUL1
  Do Format-DateTime($end_date_FY_accrual_proc, $enddate, {DEFYMD}, '', '')
  Do Format-DateTime($AccrPrcDt, $acprc, {DEFYMD}, '', '')

  if $acprc >= $begdate and $acprc <= $enddate
    let $Mode = 'FISCAL_YEAR'
  else
    let $Mode = 'NOT_FISCAL_YEAR'
  end-if

!  Display $Mode
  
End-Procedure Check-For-New-Fiscal-Year

!************************************************************************
Begin-Procedure Get-NAF-Carryover-Balance
!************************************************************************
!Retrieves information for the Latest Leave Balance
!***********************************************************************
!display 'Section = Get-NAF-Leave-Balance'
    !--------------------------------------------------------------------
    ! Calculates current leave balance. Calculates Adjustment amt to    
    ! zero out the balance
    !--------------------------------------------------------------------

Let $NAFOldDt        = ''
let $NAFoldDt_Validated = 'N'                                 

Do Check-Accrual-Date

Begin-Select

LA5.ACCRUAL_PROC_DT
LA5.SERVICE_HRS
LA5.HRS_CARRYOVER
LA5.HRS_EARNED_YTD
LA5.HRS_TAKEN_YTD
LA5.HRS_ADJUST_YTD
LA5.HRS_BOUGHT_YTD
LA5.HRS_SOLD_YTD
LA5.SERVICE_HRS_UNPROC
LA5.HRS_TAKEN_UNPROC
LA5.HRS_ADJUST_UNPROC
LA5.HRS_BOUGHT_UNPROC
LA5.HRS_SOLD_UNPROC

  Let $OldDt        = &LA5.ACCRUAL_PROC_DT
  Let #SvcHrs       = &LA5.SERVICE_HRS
  Let #UnprcSvcHrs  = &LA5.SERVICE_HRS_UNPROC
  Let #Carryover    = &LA5.HRS_CARRYOVER
  Let #EarnedYTD    = &LA5.HRS_EARNED_YTD
  Let #TakenYTD     = &LA5.HRS_TAKEN_YTD
  Let #AdjustYTD    = &LA5.HRS_ADJUST_YTD
  Let #BoughtYTD    = &LA5.HRS_BOUGHT_YTD
  Let #SoldYTD      = &LA5.HRS_SOLD_YTD
  Let #TakenUnproc  = &LA5.HRS_TAKEN_UNPROC
  Let #AdjustUnproc = &LA5.HRS_ADJUST_UNPROC
  Let #BoughtUnproc = &LA5.HRS_BOUGHT_UNPROC
  Let #SoldUnproc   = &LA5.HRS_SOLD_UNPROC
  Let #NewSvcHrs    = #Svchrs + #UnprcSvcHrs
  Let #OldLvBal     = #Carryover + #EarnedYTD - #TakenYTD + #AdjustYTD + #BoughtYTD - #SoldYTD - #TakenUnproc + #AdjustUnproc + #BoughtUnproc - #SoldUnproc
 ! If #OldLvBal < 0
 !   Display $Emplid
 !   Display 'Old Leave Balance Less Than Zero'
 ! end-if
   Let #NewCarryover = ROUND(#OldLvBal,3)
   Let #NewAdjustYTD = -1 * #NewCarryover !UO2020 - Used in COVID-19 to carryover the balance from FY 19/20 to 20/21,it was approved by city manager. We need to remove the comment for FY 20/21
   Let #NewTakenYTD  = 0
   Let #NewBoughtYTD = 0
   Let #NewSoldYTD   = 0
   Let #NewEarnedYTD = 0
   let $NAFoldDt_Validated = 'Y'                                    

!     Show '                New Svc Hrs = ' #NewSvcHrs
!     Show '             Current Lv Bal = ' #OldLvBal
!     show '               #UnprcSvcHrs = ' #UnprcSvcHrs
     
FROM PS_LEAVE_ACCRUAL LA5
WHERE LA5.EMPLID          = $Emplid
  AND LA5.EMPL_RCD       = #Emplrcd
  AND LA5.COMPANY         = $Company
  AND LA5.PLAN_TYPE       = $Plntype
  [$sql_condition_NAF]

end-select

If $NAFoldDt_Validated = 'N'                                  

  show 'NAFOldDtValidated is N for Emplid ' $emplid		
  Let #SvcHrs       = 0
  Let #UnprcSvcHrs  = 0
  Let #Carryover    = 0
  Let #EarnedYTD    = 0
  Let #TakenYTD     = 0
  Let #AdjustYTD    = 0
  Let #BoughtYTD    = 0
  Let #SoldYTD      = 0
  Let #TakenUnproc  = 0
  Let #AdjustUnproc = 0
  Let #BoughtUnproc = 0
  Let #SoldUnproc   = 0
  Let #NewSvcHrs    = #Svchrs + #UnprcSvcHrs
  Let #OldLvBal     = #Carryover + #EarnedYTD - #TakenYTD + #AdjustYTD + #BoughtYTD - #SoldYTD - #TakenUnproc + #AdjustUnproc + #BoughtUnproc - #SoldUnproc  
  Let #NewCarryover = 0
  Let #NewTakenYTD  = 0
  Let #NewAdjustYTD = 0
  Let #NewBoughtYTD = 0
  Let #NewSoldYTD   = 0
  Let #NewEarnedYTD = 0

 !else do nothing  
 end-if
 
end-procedure	!Get-NAF-Carryover-Balance

!***********************************************************************
begin-procedure Get-NAF-New-Accruals
!***********************************************************************

  Let #Accrl = #Rate
  if #ModifyPCT <> 1.0                                   !DH060704
    let #Accrl = round(#Accrl * #ModifyPCT,4)            !DH060704
  else                                                   !DH060704
    let #Accrl = #Accrl                                  !DH060704
  end-if                                                 !DH060704																									 

!  Let $AccrPrcDt = $InptAccrPrcDt
  Let #NewEarnedYTD = #NewEarnedYTD + #Accrl
  Let #NewBal = #NewCarryover + #NewEarnedYTD - #NewTakenYTD + #NewAdjustYTD + #NewBoughtYTD - #NewSoldYTD 
 
end-procedure !Get-NAF-New-Accruals

!***********************************************************************
Begin-Procedure Update-Leave-Plan-Table
!***********************************************************************

    !--------------------------------------------------------------------
    !--The delivered program updates this table with the last Accrual   -
    !--Process Date used.  PeopleCode is included in the Run Control    -
    !--Panel to ensure that an Accrual Process Date is not used that is -
    !--prior to anything used before. This code replicates the          -
    !--delivered functionality                                          -
    !--------------------------------------------------------------------


begin-sql

update PS_LEAVE_PLAN_TBL LPT
   Set ACCRUAL_PROC_DT = $AccrPrcDt
 WHERE LPT.PLAN_TYPE in ('5X','5T')
   AND LPT.EFFDT = (SELECT MAX(LPT_A.EFFDT)
                      FROM PS_LEAVE_PLAN_TBL LPT_A
                     WHERE LPT.PLAN_TYPE    = LPT_A.PLAN_TYPE
                       AND LPT.BENEFIT_PLAN = LPT_A.BENEFIT_PLAN
                       AND LPT_A.EFFDT     <= $AccrPrcDt)
end-sql

end-procedure	!Update-Leave-Plan-Table


!***********************************************************************
! SQC Files for called procedures (all standard shell sqc's)
!***********************************************************************
#include 'stdapi.sqc'    !Routines to update run status
#Include 'reset.sqc'     !Reset printer procedure
#Include 'curdttim.sqc'  !Get-Current-DateTime procedure
#Include 'datetime.sqc'  !Routines for date and time formatting
#Include 'number.sqc'    !Routines to format numbers
#Include 'datemath.sqc'  !Routines fro date arithmetic
#Include 'getcodta.sqc'  !Get-Company-Data procedure
#Include 'getdptnm.sqc'  !Get Department Name from the Department Table
