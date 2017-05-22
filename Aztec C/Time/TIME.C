void main()
{
  struct ncstime {
      char year;
      char month;
      char date;
      char day;
      char hours;
      char minutes;
      char seconds;
      char hundredths;
  } time;
  static char *weekdayname[] = {"Sun","Mon","Tues","Wednes",
                                "Thurs","Fri","Satur"};
  extern void readnsc();

  readnsc(&time);
  printf("%sday %02x/%02x/%02x %02x:%02x:%02x.%02x\n",
         weekdayname[time.day & 0xf -1],time.month,time.date,time.year,
         time.hours,time.minutes,time.seconds,time.hundredths);
}
