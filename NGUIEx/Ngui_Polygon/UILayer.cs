/*
               #########                       
              ############                     
              #############                    
             ##  ###########                   
            ###  ###### #####                  
            ### #######   ####                 
           ###  ########## ####                
          ####  ########### ####               
         ####   ###########  #####             
        #####   ### ########   #####           
       #####   ###   ########   ######         
      ######   ###  ###########   ######       
     ######   #### ##############  ######      
    #######  #####################  ######     
    #######  ######################  ######    
   #######  ###### #################  ######   
   #######  ###### ###### #########   ######   
   #######    ##  ######   ######     ######   
   #######        ######    #####     #####    
    ######        #####     #####     ####     
     #####        ####      #####     ###      
      #####       ###        ###      #        
        ###       ###        ###               
         ##       ###        ###               
__________#_______####_______####______________

                我们的未来没有BUG              
* ==============================================================================
* Filename: UILayer.cs
* Created:  2018/1/4 10:33:48
* Author:   To Hard The Mind
* Purpose:  为了通过UIPanel 控制自定义 2D mesh 的层级
* ==============================================================================
*/
using UnityEngine;

[RequireComponent(typeof(UIPanel))]
public abstract class UILayer : DisableItem {
    public abstract void UpdateLayer();
}