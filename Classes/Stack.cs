using System.Collections;

namespace classes
{
    public class Stack

    { 
        private readonly List<object> stack = new List<object>();
        
        public void Push (object obj)
        {
            if (obj == null)
                throw new InvalidOperationException("Argument is null.");

            stack.Insert (0,obj);
        }
        public object Pop ()
        {
            if (stack.Count == 0)
                throw new InvalidOperationException("Stack is empty.");

            var item = stack[0];
            stack.RemoveAt (0);
            return item;
        }
        public void Clear()
        {
            if (stack.Count == 0)
                throw new InvalidOperationException("Stack is empty.");

            stack.Clear();

        }
    }
}
