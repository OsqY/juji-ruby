class ProjectTasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: %i[ toggle destroy ]

  def create
    @task = @project.project_tasks.build(task_params)
    if @task.save
      redirect_to projects_path, notice: "Tarea agregada / Task added."
    else
      redirect_to projects_path, alert: "Error al agregar tarea."
    end
  end

  def toggle
    @task.update(completed: !@task.completed)
    redirect_to projects_path, notice: "Logro actualizado."
  end

  def destroy
    @task.destroy
    redirect_to projects_path, notice: "Tarea eliminada."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.project_tasks.find(params[:id])
  end

  def task_params
    params.require(:project_task).permit(:name)
  end
end
