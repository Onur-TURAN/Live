#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/*-----------------------------------------------------
---------bu kısımda kullanıcıdan hedef yolu + ---------
---------- dosya tipini + uzantisini almayi -----------
------------ planliyoruz.------------------------------
*/

int main(){
	
   	const char path;
 	int o,a,d;
 	printf("hangi yoldaki dosyalari duzenlemek istersiniz?\n");
	scanf("%c", &path);
 
	
  		{
			char str[100];
	  		char* nstr;
			char s;
				  int i=0;
					FILE *file;
				file = fopen("/home/biyik/Deskop/xx.txt" , "r");
				printf("<bug1>");
				if (file)//bu kısımda dosya işlemleri yapılmakta. 
		    			{
	        			// dosyayı bastan sona array ile tara ve arrayda topla
      					while((s=fgetc(file)) != EOF)
        					{
          						 str[i]=s;
          						 i++;
        					}
				//tanımadigimiz array i satir baslari ile ayiriyorz
					nstr = strtok(str, "\n"); // char* = strtok(char[]," ")-> (fonksiyon tanımı)
 	 			//nstr = IP:192.168.10.10(örnegin dosyanın icinde olan ip)
 	 
 	     			//array ile tanimladigimiz stringi printf ile yazdiriyoruz sonra kiriyoruz.
 	     				while(nstr != NULL)
		     				{
			    				printf("%s\n", str);
			    				nstr = strtok(str, "\n");
				        break;
		      				}
	      
	   			 // dosyasyı kapat
	    				fclose(file);
	    				}
		
		
	  	}
	return 0;
	}

