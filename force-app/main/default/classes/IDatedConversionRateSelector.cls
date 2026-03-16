public interface IDatedConversionRateSelector extends fflib_ISObjectSelector {
	List<DatedConversionRate> selectByISOCodeAndDate(String isoCode, Date dateoOfRate);
	List<DatedConversionRate> selectByISOCode(String isoCode);
	List<DatedConversionRate> selectByDate(Date dateoOfRate);
	List<DatedConversionRate> selectAll();
}