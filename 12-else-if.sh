read -p 'Enter your class: ' class 

if [ -z "$class" ]; then
	echo "You are suppose to give some input!! Try Again.."
	exit 1
fi


if [ "$class" = DevOps ]; then
	echo "Hello, Welcome to DevOps Training"
	exit 0
elif [ "$class" = AWS ]; then
	echo "Hello, Welcome to AWS Training"
	exit 0
else
	echo "Hello, We are not talking about $class course"
	exit 1
fi