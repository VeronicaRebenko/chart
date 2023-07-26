public class ChartController {

    public enum Algorithm {
        SchedulerOne,
        SchedulerTwo,
        SchedulerThree}

    // Amount of assigned or un-assigned Work Orders per Schedule    
    @AuraEnabled(cacheable=true)
    public static List<ScheduleData> getScheduleData(String week) {
        List<ScheduleData> scheduleDataList = new ScheduleData[Algorithm.values().size()];
        
        List<Schedule__c> schedules = [SELECT Name, Week__r.Name, Number_of_Work_Orders_in_Week__c, 
                                        Number_of_Assignments__c 
                                        FROM Schedule__c WHERE Week__r.Name =:week];
                                       
        for (Schedule__c schedule : schedules) {
            String algorithmName = extractAlgorithmName(schedule.Name);
            Integer algorithmIndex = null;
            try {
                Algorithm alg = Algorithm.valueOf(algorithmName);
                algorithmIndex = alg.ordinal();
            } catch (Exception ex) {
                continue; 
            }
            
            if (algorithmIndex != null){
                ScheduleData shed = new ScheduleData();
                shed.algorithmName = algorithmName;
                shed.week = schedule.Week__r.Name;
                shed.totalWorkOrders = schedule.Number_of_Work_Orders_in_Week__c.setscale(0);
                shed.assignments = schedule.Number_of_Assignments__c.setscale(0) ;
                shed.unassignedWorkOrders = (schedule.Number_of_Work_Orders_in_Week__c - schedule.Number_of_Assignments__c).setscale(0);
                shed.unassignedPercentage = calculateUnassignedPercentage(
                                                schedule.Number_of_Work_Orders_in_Week__c, 
                                                schedule.Number_of_Assignments__c);

                scheduleDataList.set(algorithmIndex, shed);
            }      
        }      
        return scheduleDataList;
    } 

    // Cost per Schedule    
    @AuraEnabled(cacheable=true)
    public static List<ScheduleData> getCostData(String week) {
        List<ScheduleData> scheduleDataList = new ScheduleData[Algorithm.values().size()];
        
        List<Schedule__c> schedules = [SELECT Name, Week__r.Name, Total_Cost__c,
                                        Number_of_Work_Orders_in_Week__c 
                                       FROM Schedule__c WHERE Week__r.Name =:week ORDER BY Name];
                                       
        for (Schedule__c schedule : schedules) {
            String algorithmName = extractAlgorithmName(schedule.Name);
            Integer algorithmIndex = null;
            try {
                Algorithm alg = Algorithm.valueOf(algorithmName);
                algorithmIndex = alg.ordinal();
            } catch (Exception ex) {
                continue; 
            }

            if (algorithmIndex != null){
                ScheduleData shed = new ScheduleData();
                shed.algorithmName = algorithmName;
                shed.scheduleCost = schedule.Total_Cost__c.setscale(0);
                shed.totalWorkOrders = schedule.Number_of_Work_Orders_in_Week__c.setscale(0);
                scheduleDataList.set(algorithmIndex, shed);
            }      
        }      
        return scheduleDataList;
    } 

    // Cost per Order   
    @AuraEnabled(cacheable=true)
    public static List<ScheduleData> getOrderData(String week) {
        List<ScheduleData> scheduleDataList = new ScheduleData[Algorithm.values().size()];
        
        List<Schedule__c> schedules = [SELECT Name, Week__r.Name, Total_Cost__c, Number_of_Work_Orders_in_Week__c 
                                       FROM Schedule__c WHERE Week__r.Name =:week ORDER BY Name];
                                       
        for (Schedule__c schedule : schedules) {
            String algorithmName = extractAlgorithmName(schedule.Name);
            Integer algorithmIndex = null;
            try {
                Algorithm alg = Algorithm.valueOf(algorithmName);
                algorithmIndex = alg.ordinal();
            } catch (Exception ex) {
                continue; 
            }

            if (algorithmIndex != null){
                ScheduleData shed = new ScheduleData();
                shed.algorithmName = algorithmName;
                shed.orderCost = (schedule.Total_Cost__c / schedule.Number_of_Work_Orders_in_Week__c).setscale(0) ;
                scheduleDataList.set(algorithmIndex, shed);
            }      
        }      
        return scheduleDataList;
    } 

    // Regular Time Vs Overtime data   
    @AuraEnabled(cacheable=true)
    public static List<ScheduleData> getHoursData(String week) {
        List<ScheduleData> scheduleDataList = new ScheduleData[Algorithm.values().size()];
        
        List<Schedule__c> schedules =   [SELECT Name, Week__r.Name, 
                                        Total_Hours_spent_in_Regular_Time__c, 
                                        Total_Hours_spent_in_Overtime_Hours__c 
                                        FROM Schedule__c WHERE Week__r.Name =:week ORDER BY Name];
                                       
        for (Schedule__c schedule : schedules) {
            String algorithmName = extractAlgorithmName(schedule.Name);
            Integer algorithmIndex = null;
            try {
                Algorithm alg = Algorithm.valueOf(algorithmName);
                algorithmIndex = alg.ordinal();
            } catch (Exception ex) {
                continue; 
            }

            if (algorithmIndex != null){
                ScheduleData shed = new ScheduleData();
                shed.algorithmName = algorithmName;
                shed.regularTimeData = schedule.Total_Hours_spent_in_Regular_Time__c.setscale(0);
                shed.overtimeData = schedule.Total_Hours_spent_in_Overtime_Hours__c.setscale(0);
                scheduleDataList.set(algorithmIndex, shed);
            }      
        }      
        return scheduleDataList;
    } 

    // Labor Cost and Fines   
    @AuraEnabled(cacheable=true)
    public static List<ScheduleData> getMoneyData(String week) {
        List<ScheduleData> scheduleDataList = new ScheduleData[Algorithm.values().size()];
        
        List<Schedule__c> schedules =   [SELECT Name, Week__r.Name, 
                                        Total_Labour_Cost__c, Total_Fine__c,
                                        Total_Fine_Unfinished_Work_Orders__c 
                                        FROM Schedule__c WHERE Week__r.Name =:week ORDER BY Name];
                                       
        for (Schedule__c schedule : schedules) {
            String algorithmName = extractAlgorithmName(schedule.Name);
            Integer algorithmIndex = null;
            try {
                Algorithm alg = Algorithm.valueOf(algorithmName);
                algorithmIndex = alg.ordinal();
            } catch (Exception ex) {
                continue; 
            }

            if (algorithmIndex != null){
                ScheduleData shed = new ScheduleData();
                shed.algorithmName = algorithmName;
                shed.laborMoney = schedule.Total_Labour_Cost__c.setscale(0);
                shed.lateFine = schedule.Total_Fine__c.setscale(0);
                shed.unfinishedFine = schedule.Total_Fine_Unfinished_Work_Orders__c.setscale(0);
                scheduleDataList.set(algorithmIndex, shed);
            }      
        }      
        return scheduleDataList;
    } 


    private static String extractAlgorithmName(String scheduleName) {
        Integer startIndex = scheduleName.indexOf('generated by ') + 'generated by '.length();
        return scheduleName.substring(startIndex);
        
    }

    private static Decimal calculateUnassignedPercentage(Decimal totalWorkOrders, Decimal assignments) {
        Decimal unassignedPercentage = 0;
        if (totalWorkOrders != 0) {
            unassignedPercentage = (totalWorkOrders - assignments) / totalWorkOrders * 100;
        }
        return unassignedPercentage.setscale(2);
    }

    
    public class ScheduleData {

        @AuraEnabled public String algorithmName;
        @AuraEnabled public String week;
        @AuraEnabled public Decimal totalWorkOrders;
        @AuraEnabled public Decimal assignments;
        @AuraEnabled public Decimal unassignedWorkOrders;
        @AuraEnabled public Decimal unassignedPercentage;
        @AuraEnabled public Decimal scheduleCost;
        @AuraEnabled public Decimal orderCost;
        @AuraEnabled public Decimal regularTimeData;
        @AuraEnabled public Decimal overtimeData;
        @AuraEnabled public Decimal laborMoney;
        @AuraEnabled public Decimal lateFine;
        @AuraEnabled public Decimal unfinishedFine;
        @AuraEnabled public Decimal dataOne;
        @AuraEnabled public Decimal dataTwo;
        @AuraEnabled public Decimal dataThree;

    }
}
