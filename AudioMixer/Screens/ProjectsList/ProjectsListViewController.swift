// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class ProjectsListViewController: UIViewController {
  private let viewModel: ProjectsListViewModel

  private lazy var collectionView = makeCollectionView()
  private var dataSource: UICollectionViewDiffableDataSource<Int, ProjectModel>?

  private lazy var createButton = makeButton(
    image: UIImage(systemName: "plus"),
    action: #selector(createNewProject)
  )
  private lazy var titleLabel = makeTitleLabel()

  init(
    viewModel: ProjectsListViewModel
  ) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.isHidden = true

    setupUI()
    viewModel.viewDidLoad()
  }

  func updateCollectionView() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, ProjectModel>()
    snapshot.appendSections([0])
    snapshot.appendItems(viewModel.projects)

    DispatchQueue.main.async { [weak self] in
      self?.dataSource?.apply(
        snapshot,
        animatingDifferences: true
      )
    }
  }

  private func setupUI() {
    let headerView = UIView()
    view.addSubviews(collectionView, headerView)

    headerView.addSubviews(titleLabel, createButton)

    titleLabel.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.equalToSuperview().offset(16)
      make.right.equalTo(createButton.snp.left).offset(-16)
    }

    createButton.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().offset(-16)
      make.size.equalTo(CGSize(width: 36, height: 36))
    }

    headerView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.left.equalTo(view.snp.left)
      make.right.equalTo(view.snp.right)
      make.height.equalTo(Constants.cellHeight)
    }

    collectionView.snp.makeConstraints { make in
      make.top.equalTo(headerView.snp.bottom).offset(12)
      make.bottom.equalToSuperview()
      make.left.equalTo(view.snp.left)
      make.right.equalTo(view.snp.right)
    }
  }

  private func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.attributedText = NSAttributedString(
      string: "Проекты",
      attributes: [
        .foregroundColor: UIColor.accentColor,
        .font: UIFont.systemFont(ofSize: 30, weight: .bold),
      ]
    )
    return label
  }

  private func makeButton(image: UIImage?, action: Selector) -> UIButton {
    let button = UIButton()
    button.smoothCornerRadius = .inset4
    button.backgroundColor = .white
    button.setImage(image, for: .normal)
    button.tintColor = .black
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  private func makeCollectionView() -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = Constants.interItemSpacing

    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.backgroundColor = .clear
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.delaysContentTouches = false

    let dataSource = UICollectionViewDiffableDataSource<Int, ProjectModel>(
      collectionView: collectionView,
      cellProvider: { [weak self] collectionView, indexPath, itemIdentifier in
        self?.makeCell(
          for: collectionView,
          indexPath: indexPath,
          project: itemIdentifier
        )
      }
    )
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ProjectCell")
    collectionView.dataSource = dataSource
    self.dataSource = dataSource
    collectionView.delegate = self
    return collectionView
  }

  private func makeCell(
    for collectionView: UICollectionView,
    indexPath: IndexPath,
    project: ProjectModel
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "ProjectCell",
      for: indexPath
    )
    cell.backgroundConfiguration = .listGroupedCell()
    var config = UIListContentConfiguration.cell()
    config.text = project.name
    config.secondaryAttributedText = NSAttributedString(
      string: "Updated: \(project.updateDate.formatted())",
      attributes: [
        .foregroundColor: UIColor.lightGray,
      ]
    )
    config.image = UIImage(systemName: "music.note.list")
    config.imageProperties.tintColor = .black
    config.imageToTextPadding = 8
    cell.contentConfiguration = config
    cell.smoothCornerRadius = 8
    cell.clipsToBounds = true
    return cell
  }

  @objc
  private func createNewProject() {
    viewModel.createProjectTapped()
  }
}

extension ProjectsListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    CGSize(width: UIScreen.main.bounds.width, height: Constants.cellHeight)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    collectionView.deselectItem(at: indexPath, animated: true)
    viewModel.didSelectProject(at: indexPath)
  }
}

fileprivate enum Constants {
  static let cellHeight = 60.0
  static let interItemSpacing = 6.0
}
