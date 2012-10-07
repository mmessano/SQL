--List of useful Regular expressions (regex)
--Positive integers

^[1-9]+[0-9]*$

--Positive decimal values

(^\d*\.?\d*[0-9]+\d*$)|(^[0-9]+\d*\.\d*$)

--Percentage (2 decimal places)

^-?[0-9]{0,2}(\.[0-9]{1,2})?$|^-?(100)(\.[0]{1,2})?$

--List of semi-colon seperated email addresses

^([\w\.*\-*]+@([\w]\.*\-*)+[a-zA-Z]{2,9}(\s*;\s*[\w\.*\-*]+@([\w]\.*\-*)+[a-zA-Z]{2,9})*)$

--German Date (dots instead of slashes)

^(((0[1-9]|[12]\d|3[01]).(0[13578]|1[02]).(\d{2}))|((0[1-9]|[12]\d|30).(0[13456789]|1[012]).(\d{2}))|((0[1-9]|1\d|2[0-8]).02.(\d{2}))|(29.02.((0[48]|[2468][048]|[13579][26])|(00))))$

--E-mail address

^[\w-]+(\.[\w-]+)*@([a-z0-9-]+(\.[a-z0-9-]+)*?\.[a-z]{2,6}|(\d{1,3}\.){3}\d{1,3})(:\d{4})?$