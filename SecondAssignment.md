<h1>15 operations with their descriptions and uses</h1>

Assignment Operator (=):<br/>
Usage: variable=value<br/>
Purpose: Assigns a value to a variable.


Arithmetic Operators (+, -, *, /, %):<br/>
Usage: result=$((5 + 3)), result=$((var1 * var2))<br/>
Purpose: Performs basic arithmetic operations on numbers.


Comparison Operators (==, !=, >, <, >=, <=):<br/>
Usage: if [ "$var1" -eq "$var2" ]<br/>
Purpose: Compares values or expressions and returns true (0) or false (1).<br/>


String Concatenation Operator (+=):<br/>
Usage: str1+="newstring" <br/>
Purpose: Appends a string to an existing string variable.


String Comparison Operators (==, !=):<br/>
Usage: if [ "$str1" == "$str2" ]<br/>
Purpose: Compares two strings for equality or inequality.


Logical Operators (&&, ||, !): <br/>
Usage: if [ "$a" -eq 1 ] && [ "$b" -eq 2 ] <br/>
Purpose: Performs logical AND, OR, and NOT operations in conditional statements.


Increment/Decrement Operators (++, --): <br/>
Usage: ((var++)), ((var--)) <br/>
Purpose: Increments or decrements a numeric variable by 1.


Assignment Operators (+=, -=, *=, /=, %=): <br/>
Usage: var1+=5, var2/=2 <br/>
Purpose: Perform arithmetic operations and assign the result back to a variable.


Conditional Operator (ternary) (? :): <br/>
Usage: result=$((condition ? value_if_true : value_if_false)) <br/>
Purpose: Provides a compact way to express conditional statements.



Substring Extraction Operator (substring): <br/>
Usage: substr=${str:2:4} <br/>
Purpose: Extracts a substring from a string.


Command Substitution Operator (command or $(command)): <br/>
Usage: result=$(date) <br/>
Purpose: Executes a command and captures its output for further use.


Array Operators (${array[@]}): <br/>
Usage: element=${array[2]}, length=${#array[@]} <br/>
Purpose: Access elements and determine the length of an array.

File Test Operators (-e, -f, -d, -r, -w, -x): <br/>
Use: To test file properties (existence, type, readability, writability, executability). <br/>
Example: [ -e "$file" ] checks if a file exists.


String Length Operator (#): <br/>
Use: To find the length of a string. <br/>
Example: length=${#str} stores the length of str in the variable length.


Ternary Operator (? :): <br/>
Use: To create conditional expressions. <br/>
Example: result=$((a > b ? a : b)) assigns the larger of a and b to result.





