// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class LayersView: UIView {
  private let audioController: AudioControlling
  private let heightDidChange: (_ height: CGFloat) -> Void
  private let didSelectLayer: (_ layer: LayerModel) -> Void

  private lazy var collectionView = makeCollectionView()
  private var dataSource: UICollectionViewDiffableDataSource<Int, LayerModel>?
  private var layers = [LayerModel]() {
    didSet {
      updateCollectionView()
    }
  }

  var isEmpty: Bool {
    layers.isEmpty
  }

  init(
    audioController: AudioControlling,
    didSelectLayer: @escaping (_ layer: LayerModel) -> Void,
    heightDidChange: @escaping (_ height: CGFloat) -> Void
  ) {
    self.audioController = audioController
    self.didSelectLayer = didSelectLayer
    self.heightDidChange = heightDidChange
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(collectionView)
    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  func configure(with layers: [LayerModel]) {
    self.layers = layers
  }

  func addLayer(_ layer: LayerModel) {
    self.layers.insert(layer, at: .zero)
  }

  private func updateCollectionView() {
    let height = CGFloat(layers.count) * (Constants.cellHeight + Constants.interItemSpacing) + safeAreaInsets.bottom
    if height <= Constants.maxHeight {
      heightDidChange(height)
    }

    var snapshot = NSDiffableDataSourceSnapshot<Int, LayerModel>()
    snapshot.appendSections([0])
    snapshot.appendItems(layers)

    DispatchQueue.main.async { [weak self] in
      self?.dataSource?.apply(
        snapshot,
        animatingDifferences: true
      )
    }
  }

  private func makeCollectionView() -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = Constants.interItemSpacing

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.insetsLayoutMarginsFromSafeArea = false
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.delaysContentTouches = false
    collectionView.contentInset.bottom = safeAreaInsets.bottom

    let dataSource = UICollectionViewDiffableDataSource<Int, LayerModel>(
      collectionView: collectionView,
      cellProvider: { [weak self] collectionView, indexPath, itemIdentifier in
        self?.makeCell(for: collectionView, indexPath: indexPath, layer: itemIdentifier)
      }
    )
    collectionView.register(LayerCell.self, forCellWithReuseIdentifier: LayerCell.reuseIdentifier)
    collectionView.dataSource = dataSource
    self.dataSource = dataSource
    collectionView.delegate = self
    return collectionView
  }

  private func makeCell(
    for collectionView: UICollectionView,
    indexPath: IndexPath,
    layer: LayerModel
  ) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: LayerCell.reuseIdentifier,
      for: indexPath
    ) as? LayerCell
    else { return UICollectionViewCell() }
    cell.configure(with: layer, audioController: audioController) { [weak self] in
      guard let layerIndex = self?.layers.firstIndex(of: layer) else { return }
      self?.layers.remove(at: layerIndex)
      self?.updateCollectionView()
    }
    return cell
  }
}

extension LayersView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let layer = layers[safe: indexPath.item] else {
      Logger.log("Incorrect state of layers property")
      return
    }
    didSelectLayer(layer)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    CGSize(width: UIScreen.main.bounds.width, height: Constants.cellHeight)
  }
}

fileprivate enum Constants {
  static let cellHeight = 40.0
  static let interItemSpacing = 8.0
  static let maxHeight = UIScreen.main.bounds.height / 2
}
