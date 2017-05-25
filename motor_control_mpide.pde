  #include <AccelStepper.h>
  
  AccelStepper stepper_ls(1, 9, 8); //set up pins for lead screw motor
  AccelStepper stepper_main(1, 7, 6); //set up pins for main motor
  
  unsigned int switch_ls = 5; //set up pin for lead screw motor switch
  unsigned int switch_main = 4; //set up pin for main motor switch
  boolean ls_enable;
  boolean main_enable;
  boolean brush_enable;
  boolean serial_available;
  
  unsigned int pos_ls = -1500; //target distance of lead screw motor
  unsigned int adjust_pos_ls = 0; //target position of lead screw when in "forth" state
  unsigned int pos_main = 2500; //target distance of main motor
  unsigned int brush_spd = 750; //initial brush speed

  unsigned int flexpin = A0;
  unsigned int pace = 100;
  unsigned int analoginput;
  unsigned int count = 0;//The anti-noise count
  unsigned int reach = 10;//The analog input when the brush reaches the skin
  unsigned int loopcount = 400;//This parameter makes the system to detect the touching pressure every 2000 loops
  
  //Define different states
  boolean waitForCommand;
  boolean forth;
  boolean back;
  boolean initiate;
  boolean touch;
  boolean stopBrush;
  
  void setup()
  {
    Serial.begin(9600);
    pinMode(switch_ls, INPUT);
    pinMode(switch_main, INPUT);
    pinMode(flexpin,INPUT);
    stepper_ls.setMaxSpeed(1000);
    stepper_ls.setAcceleration(500);
    stepper_main.setMaxSpeed(2000);
    stepper_main.setAcceleration(500);
    
    initiate = true;
    ls_enable = true;
    main_enable = true;
  }
  
  void loop()
  {
    if(initiate == true){
      //Serial.println('I');
      if(ls_enable == true){
        stepper_ls.setSpeed(-1000);
        stepper_ls.runSpeed();
      }
      if(main_enable == true){
        stepper_main.setSpeed(-2000);
        stepper_main.runSpeed();
      }
      if(digitalRead(switch_ls) == HIGH){
        stepper_ls.setCurrentPosition(0);
        ls_enable = false;
        //Serial.println("Left switch is being closed!!!");
      }
      if(digitalRead(switch_main) == HIGH)
      {
        stepper_main.setCurrentPosition(0);
        main_enable = false;
        //Serial.println("Right switch is being closed!!!");
      }
      if(ls_enable == false && main_enable == false){
        initiate = false;
        waitForCommand = true;
      }
    }
    
    else if(waitForCommand == true){
      count = 0;
      serial_available = Serial.available();
      if(serial_available)
      {
        String command; //format is command
                        //command is "s" or "e"
        command = Serial.readString();
        if(command == "s")
        {
          brush_enable = true; 
        }
        else if(command == "e")
        {
          brush_enable = false;
        }
      }
      if(brush_enable == true)
      {
        waitForCommand = false;
        touch = true; 
        stepper_ls.setSpeed(-1500);
        stepper_ls.moveTo(pos_ls);
      }
      else
      {
        waitForCommand = false;
        stopBrush = true;		
      }
    }
  
    else if(touch == true)
    {
      stepper_ls.run();
      if(stepper_ls.currentPosition() == pos_ls)
      {
        touch = false;
        forth = true;
        stepper_main.moveTo(pos_main);
        stepper_main.setSpeed(brush_spd);
        if(serial_available)
        {
          Serial.print("t\r\n");
          serial_available = false;
        }
      }
    }
    
    else if(forth == true)
    {
       stepper_main.runSpeedToPosition();
       if (stepper_main.currentPosition() == pos_main)
       {
         forth = false;
         back = true;
       }
     }
    
    else if(back == true){
      if(stepper_main.targetPosition() != 0)
      {
        stepper_main.moveTo(0);
        stepper_main.setSpeed(brush_spd);
      }
      if(stepper_main.currentPosition() == 0)
      {
        back = false;
        waitForCommand = true;
      }
      stepper_main.runSpeedToPosition();
    }
	
    else if(stopBrush == true)
    {
      if((stepper_ls.currentPosition() != 0) && (stepper_ls.targetPosition() != 0))
      {
        stepper_ls.moveTo(0);
        stepper_ls.setSpeed(1500);
      }
      if(stepper_ls.currentPosition() == 0)
      {
        stopBrush = false;
        waitForCommand = true;
      }
      stepper_ls.runSpeedToPosition();
    }
  }

