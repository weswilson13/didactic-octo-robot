namespace classes
{
    public class Stopwatch
    {
        private DateTime _startTime;
        private DateTime StartTime 
        {
            get { return _startTime; }
            set {
                if (_startTime != DateTime.MinValue && _startTime > StopTime)
                    throw new InvalidOperationException("Stopwatch is already started.");

                this._startTime = value;               
            }
        }
        private DateTime StopTime { get; set; }
        public void Start()
        {
            StartTime = DateTime.Now;
            Console.WriteLine(StartTime);
        }
        public void Stop()
        {
            StopTime = DateTime.Now;
            Console.WriteLine(StopTime);
        }
        public TimeSpan Duration
        {
            get
            { 
                var timeSpan = StopTime - StartTime;
                
                return timeSpan;
            }
        }
    }
}
