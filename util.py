#***************************************************#
# FUNCIONES PARA EL MANEJO DE FECHAS                #
#***************************************************#
def str2date(string):
    """String must be with format %Y%m%d%H%M%S"""
    from datetime import datetime as dt
    return dt.strptime(string, '%Y%m%d%H%M%S')

def date2str(date):
    '''
    Date: a datetime object.
    Output: string with format %Y%m%d%H%M%S
    '''
    from  datetime import datetime as dt
    return dt.strftime(date, '%Y%m%d%H%M%S')

def datespan(startDate, endDate, delta):
    '''
    La funcion devuelve un "generator" que contiene un objecto date
    Input:
        starDate (objeto): de la clase datetime que indica la fecha inicial
        endDate (objeto): de la clase datetime que indica la fecha final
        delta (objeto): de la clase datetime que indica el intervalo temporal
    '''
    currentDate = startDate
    while currentDate < endDate:
        yield currentDate
        currentDate += delta

def get_dates(times):
    from datetime import timedelta
    '''
    La funcion devuelve una lista que contiene objetos datetime
    times = [ini, end, freq] : ini, end (str), freq (int in seconds)

    '''
    #Convert to date objects
    inidate = str2date(times[0])
    enddate = str2date(times[1])
    delta = timedelta(seconds=times[2])

    dates = []
    #Loop over dates
    for date in datespan(inidate, enddate+delta, delta):
        dates.append(date)
    return dates

