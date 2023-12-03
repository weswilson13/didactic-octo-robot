namespace classes
{
    public class Post
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public DateTime DateCreated { get; set; }
        public int VoteValue { get; private set; }
        public Post(string title, string description)
        {
            Title = title;
            Description = description;
            DateCreated = DateTime.Now;
        }
        public void UpVote()
        {
            VoteValue++;   
        }
        public void DownVote()
        {
            if (VoteValue > 0)
            {

                VoteValue--;
            }
        }
    }
}
