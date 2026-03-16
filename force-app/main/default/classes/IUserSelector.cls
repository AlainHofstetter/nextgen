public interface IUserSelector  extends fflib_ISObjectSelector {
	User selectById(Id userId);
	List<User> selectAll();
}