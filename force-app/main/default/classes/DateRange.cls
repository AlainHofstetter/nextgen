public without sharing class DateRange {

  private Date dateFrom;
  private Date dateTo;

  public DateRange() {
  }

  public DateRange(String dateFrom, String dateTo) {
    this.dateFrom = (dateFrom != null && dateFrom != '') ? Date.valueOf(dateFrom) : null;
    this.dateTo = (dateTo != null && dateTo != '') ? Date.valueOf(dateTo) : null;
  }

  public Boolean isNull() {
    return (this.dateFrom == null || this.dateTo == null);
  }

  public Boolean isInBetween(Date comparingDate) {
    return (comparingDate >= dateFrom && comparingDate <= dateTo);
  }

}