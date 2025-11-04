public class BusScheduleCache {
    // Private class variable for org partition
    private Cache.OrgPartition part;

    // Constructor
    public BusScheduleCache() {
        // Create a new instance of Cache.OrgPartition with the partition name
        part = Cache.Org.getPartition('local.BusSchedule');
    }

    // Method to put schedule in cache
    public void putSchedule(String busLine, Time[] schedule) {
        // Store schedule in the cache
        part.put(busLine, schedule);
    }

    // Method to get schedule from cache
    public Time[] getSchedule(String busLine) {
        // Retrieve the schedule from the cache
        Time[] schedule = (Time[]) part.get(busLine);

        // Handle cache miss
        if (schedule == null) {
            // Return default schedule (8 AM, 5 PM)
            schedule = new Time[] {
                Time.newInstance(8, 0, 0, 0),
                Time.newInstance(17, 0, 0, 0)
            };
        }
        return schedule;
    }
}