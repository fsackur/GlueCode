using System;

namespace Example
{
    public class MyClass {

        MyClass () {
            this.ID = Guid.new();
        }

        private Guid ID;

        public string ToString() {
            return this.ID.ToString();
        }

        public string ToString(string formatQualifier) {
            if (formatQualifier == 'Upper') {
                return this.ID.ToString().ToUpper();
            } else {
                return this.ID.ToString().ToLower();
            }
        }
    }
}