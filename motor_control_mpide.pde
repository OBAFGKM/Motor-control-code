  #include <AccelStepper.h>
  
  AccelStepper stepper_ls(1, 9, 8); //set up pins for lead screw motor
  AccelStepper stepper_main(1, 7, 6); //set up pins for main motor
  
  unsigned int switch_ls = 5; //set up pin for lead screw motor switch
  unsigned int switch_main = 4; //set up pin for main motor switch
  boolean ls_enable;
  boolean main_enable;
  boolean brush_enable;
  
  unsigned int pos_ls = 800; //target distance of lead screw motor
  unsigned int adjust_pos_ls = 0; //target position of lead screw when in "brush" state
  unsigned int pos_main = 3000; //target distance of main motor
  unsigned int brush_spd = 1000; //initial brush speed
  // unsigned int retreat_spd = 2000; //retreat speed of brush
//  unsigned int brush_num;
  unsigned int flexpin = A0;
  unsigned int pace = 100;
  unsigned int analoginput;
  unsigned int count = 0;//The anti-noise count
  unsigned int reach = 10;//The analog input when the brush reaches the skin
  unsigned int loopcount = 400;//This parameter makes the system to detect the touching pressure every 2000 loops
  
  //Define different states
  boolean waitForCommand;
  boolean brush;
  boolean retreat;
  boolean initiate;
  boolean touch;
  
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
        Serial.println("Left switch is being closed!!!");
      }
      if(digitalRead(switch_main) == HIGH)
      {
        stepper_main.setCurrentPosition(0);
        main_enable = false;
        Serial.println("Right switch is being closed!!!");
      }
      if(ls_enable == false && main_enable == false){
        initiate = false;
        waitForCommand = true;
      }
    }
    
    else if(waitForCommand == true){
      count = 0;
      if(Serial.available())
      {
        String command; //format is command#
                        //command is "START" or "STOP"
        command = Serial.readStringUntil('#');
        if(command == "START")
        {
          brush_enable = true; 
        }
        else if(command == "STOP")
        {
          brush_enable = false;
        }
	  }
      if(brush_enable == true)
      {
        waitForCommand = false;
        touch = true; 
      }
      // stepper_ls.setSpeed(-1500);
    }
  
    else if(touch == true)
    {
      while (count < 3)//The index is set as 2, bigger the index, better the anti-noise effect will be but the longer delay we have.
      {
        analoginput = analogRead(flexpin);//Read the analog input
        if (analoginput > 20)
        {
          count = count + 1;//Anti-noise
        }
        else if(analoginput <= 20)
        {
          count = 0;//The analog read should reach the threshold a few times in a row
        }
        stepper_ls.runSpeed();
      }
      Serial.print("touched\r\n");
      touch = false;
      brush = true;
      adjust_pos_ls = stepper_ls.currentPosition();
      stepper_ls.moveTo(adjust_pos_ls);
      stepper_main.moveTo(pos_main);
      stepper_main.setSpeed(brush_spd);
    }
    
    else if(brush == true)
    {
       if (analogRead(A0) >= 5)
       {
         stepper_ls.setSpeed(1000);
       }
       if (analogRead(A0) == 0)
       {
         stepper_ls.setSpeed(-1000);
       }
       if ((analogRead(A0) != 0) && (analogRead(A0) < 5))
       {
         stepper_ls.setSpeed(0);
       }
       stepper_ls.runSpeed();
       stepper_main.runSpeed();
       if (stepper_main.currentPosition() == 2500)
       {
         brush = false;
         retreat = true;
       }
     }
    
    else if(retreat == true){
      if((stepper_ls.currentPosition() != 0) && (stepper_ls.targetPosition() != 0))
      {
        stepper_ls.moveTo(0);
        stepper_ls.setSpeed(1500);
      }
      if((stepper_ls.currentPosition() == 0) && (stepper_main.targetPosition() != 0))
      {
        stepper_main.moveTo(0);
        stepper_main.setSpeed(brush_spd);
      }
      if(stepper_main.currentPosition() == 0)
      {
        retreat = false;
        waitForCommand = true;
      }
      stepper_ls.runSpeedToPosition();
      stepper_main.runSpeedToPosition();
    }
  }

